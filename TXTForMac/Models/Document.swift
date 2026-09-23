import AppKit
import Foundation

/// 单个文档的全部状态（ADR-005）。
///
/// 文本本体保存在该文档自己的 `NSTextView.textStorage` 里（惰性创建，切换标签时视图
/// 随文档走），模型不再持有第二份文本拷贝；撤销栈随视图实例存在，保证跨标签撤销正确。
/// 未显示过的文档内容暂存 `pendingText`，首次获得视图时灌入。
@MainActor
@Observable
final class Document: Identifiable {
    let id = UUID()

    private(set) var fileURL: URL?
    private(set) var encoding: TextEncoding
    private(set) var lineEnding: LineEnding
    private(set) var hasBOM: Bool
    private(set) var isDirty: Bool
    private(set) var loadPolicy: DocumentLoadPolicy
    private(set) var pendingText: String?

    /// 每文档缩放（US-003）
    var zoomScale: CGFloat = 1
    /// 弱引用持有该文档的文本视图（由 DocumentStore/工厂创建）
    weak var textView: NSTextView?
    /// 记录视图创建时的字数，用于脏判定
    private var savedCharacterCount: Int = 0

    /// 从磁盘加载的文档
    init(loaded: LoadedFile, url: URL) {
        fileURL = url
        encoding = loaded.encoding
        lineEnding = loaded.lineEnding
        hasBOM = loaded.hasBOM
        loadPolicy = loaded.policy
        isDirty = false
        pendingText = loaded.text
        savedCharacterCount = loaded.text.count
    }

    /// 新建空白文档
    init(settings: AppSettings) {
        encoding = settings.defaultEncoding
        hasBOM = settings.defaultEncoding == .utf8BOM
        if settings.defaultEncoding == .utf8BOM {
            encoding = .utf8
        }
        lineEnding = settings.defaultLineEnding
        loadPolicy = .normal
        isDirty = false
        pendingText = ""
        savedCharacterCount = 0
    }

    // MARK: - 派生状态

    var isReadOnly: Bool {
        loadPolicy == .readOnly
    }

    var displayName: String {
        fileURL?.lastPathComponent ?? LocalizationSnapshot.string("document.untitled")
    }

    /// 当前文本（视图存在时以视图为准）
    var text: String {
        textView?.string ?? pendingText ?? ""
    }

    // MARK: - 内容操作

    /// 取得（或创建）该文档的文本视图。
    func acquireTextView(factory: (Document) -> NSTextView) -> NSTextView {
        if let textView {
            return textView
        }
        let view = factory(self)
        textView = view
        return view
    }

    /// 把暂存内容灌入文本视图（视图创建后调用一次）。
    func drainPendingText(into view: NSTextView) {
        guard let pendingText else { return }
        view.string = pendingText
        self.pendingText = nil
    }

    /// 记录用户编辑（由视图代理回调）。
    func noteUserEdit() {
        isDirty = true
    }

    /// 保存成功后的状态归档。
    func markSaved(to url: URL, encoding: TextEncoding, lineEnding: LineEnding, hasBOM: Bool) {
        fileURL = url
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.hasBOM = hasBOM
        isDirty = false
        savedCharacterCount = text.count
    }

    /// 会话恢复：还原编码/换行符/BOM 状态并标记脏（内容经 replaceWholeText 写入）。
    func restoreState(encoding: TextEncoding, lineEnding: LineEnding, hasBOM: Bool) {
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.hasBOM = hasBOM
        isDirty = true
    }

    /// 就地转换换行符并标记脏。
    func convertLineEnding(to target: LineEnding) {
        guard target != lineEnding else { return }
        let converted = target.applying(to: text)
        replaceWholeText(with: converted, undoably: false)
        lineEnding = target
        isDirty = true
    }

    /// 替换全部文本。
    func replaceWholeText(with newText: String, undoably: Bool) {
        guard let textView else {
            pendingText = newText
            return
        }
        guard let storage = textView.textStorage else { return }
        if !undoably {
            storage.beginEditing()
        }
        storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: newText)
        if !undoably {
            storage.endEditing()
            textView.undoManager?.removeAllActions()
        }
        pendingText = nil
    }

    /// 该文档的当前字节量估算（用于保存前提示），以字符数近似。
    var approximateCharacterCount: Int {
        text.count
    }
}
