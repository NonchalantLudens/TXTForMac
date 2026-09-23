import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 一个窗口的全部状态与命令路由（T-012/T-013/T-014/T-015）。
///
/// 菜单命令经 `focusedSceneValue` 汇入当前 key window 的 Workspace；
/// 文件操作全部经 `FileIOService`，本类不做 IO 细节。
@MainActor
@Observable
final class Workspace: NSObject {
    let store = DocumentStore()
    let settings: SettingsStore
    let coordinator = EditorCoordinator()

    // MARK: 状态栏数据（T-014）

    private(set) var cursorLine = 1
    private(set) var cursorColumn = 1
    private(set) var characterCount = 0
    private(set) var selectedCount = 0
    private(set) var zoomPercent = 100

    // MARK: 窗口级状态

    /// 顶部提示条（T-016）
    var banner: Banner?
    private(set) var showStatusBar = SettingsStore.shared.settings.showStatusBar
    private(set) var showTabBar = SettingsStore.shared.settings.showTabBar

    // MARK: 查找会话（T-017/T-018/T-019）

    let find = FindSession()
    var findMode: FindMode?

    // MARK: 自动保存（T-030）

    var autosaveTimer: Timer?

    enum Banner: Equatable {
        case largeFileWarning(byteCount: Int)
    }

    weak var window: NSWindow?
    var boundWindowID: ObjectIdentifier?

    override init() {
        settings = .shared
        super.init()
        bindCoordinator()
    }

    private func bindCoordinator() {
        coordinator.onTextChange = { [weak self] in
            self?.refreshWindowEditedFlag()
            self?.refreshStatusMetrics()
        }
        coordinator.onSelectionChange = { [weak self] in
            self?.refreshStatusMetrics()
        }
    }

    // MARK: 视图装配

    func makeTextView(for document: Document) -> NSTextView {
        TextViewFactory.makeTextView(
            for: document,
            settings: settings.settings,
            coordinator: coordinator
        )
    }

    func bind(window: NSWindow) {
        guard boundWindowID != ObjectIdentifier(window) else { return }
        boundWindowID = ObjectIdentifier(window)
        self.window = window
        window.delegate = self
        WorkspaceRegistry.shared.register(self, for: window)
        refreshStatusMetrics()
        refreshWindowEditedFlag()
    }

    /// 记录最近文件（T-024）：去重、上限来自设置。
    func noteRecentFile(at url: URL) {
        let path = url.path
        settings.update { settings in
            var recents = settings.recentFiles.filter { $0 != path }
            recents.insert(path, at: 0)
            let limit = max(settings.recentFilesLimit, 0)
            if recents.count > limit {
                recents = Array(recents.prefix(limit))
            }
            settings.recentFiles = recents
        }
    }

    // MARK: 文档命令

    func newDocument() {
        store.open(Document(settings: settings.settings))
        refreshStatusMetrics()
    }

    func closeCurrentWindow() {
        window?.performClose(nil)
    }

    func setLineEnding(_ target: LineEnding) {
        guard let document = store.currentDocument else { return }
        document.convertLineEnding(to: target)
        refreshWindowEditedFlag()
    }

    // MARK: 编辑命令

    func insertTimeDate() {
        guard let textView = store.currentDocument?.textView, textView.isEditable else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = settings.settings.timeDateFormat
        textView.insertText(
            formatter.string(from: Date.now),
            replacementRange: textView.selectedRange()
        )
    }

    func zoomIn() {
        adjustZoom(by: 0.1)
    }

    func zoomOut() {
        adjustZoom(by: -0.1)
    }

    func zoomReset() {
        guard let document = store.currentDocument, let textView = document.textView else { return }
        document.zoomScale = 1
        TextViewFactory.applyZoom(1, to: textView, settings: settings.settings)
        zoomPercent = 100
    }

    private func adjustZoom(by delta: CGFloat) {
        guard let document = store.currentDocument, let textView = document.textView else { return }
        let clamped = min(5, max(0.5, document.zoomScale + delta))
        document.zoomScale = clamped
        TextViewFactory.applyZoom(clamped, to: textView, settings: settings.settings)
        zoomPercent = Int((clamped * 100).rounded())
    }

    func toggleWordWrap() {
        let enabled = !settings.settings.defaultWordWrap
        settings.update { $0.defaultWordWrap = enabled }
        if let textView = store.currentDocument?.textView {
            TextViewFactory.applyWordWrap(enabled, to: textView)
        }
    }

    func toggleStatusBar() {
        showStatusBar.toggle()
        settings.update { $0.showStatusBar = showStatusBar }
    }

    func applyAppearance(_ preference: ThemePreference) {
        switch preference {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    func showFontPanel() {
        NSFontManager.shared.orderFrontFontPanel(self)
    }

    func sendEditorAction(_ selector: Selector) {
        NSApp.sendAction(selector, to: nil, from: nil)
    }

    // MARK: 状态刷新

    func dismissBanner() {
        banner = nil
    }

    func refreshStatusMetrics() {
        guard let document = store.currentDocument else {
            cursorLine = 1
            cursorColumn = 1
            characterCount = 0
            selectedCount = 0
            return
        }
        let text = document.text
        characterCount = text.count
        let selection = document.textView?.selectedRange() ?? NSRange(location: 0, length: 0)
        selectedCount = selection.length == 0 ? 0 : Self.characterCount(
            in: text, utf16Range: selection
        )
        let position = Self.lineColumn(of: text, utf16Location: selection.location)
        cursorLine = position.line
        cursorColumn = position.column
    }

    func refreshWindowEditedFlag() {
        window?.isDocumentEdited = store.dirtyCount > 0
    }

    func presentError(_ error: Error) {
        if let window {
            window.presentError(error)
        } else {
            NSApp.presentError(error)
        }
    }

    /// UTF-16 位置（NSRange 语义）→ 行/列。
    static func lineColumn(of text: String, utf16Location location: Int) -> (line: Int, column: Int) {
        var line = 1
        var column = 1
        var consumed = 0
        for character in text {
            if consumed >= location {
                break
            }
            if character == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            consumed += character.utf16.count
        }
        return (line, column)
    }

    /// UTF-16 区间内的字符数（按字素计）。
    static func characterCount(in text: String, utf16Range range: NSRange) -> Int {
        let nsText = text as NSString
        guard range.location >= 0,
              range.location + range.length <= nsText.length else { return 0 }
        return nsText.substring(with: range).count
    }
}
