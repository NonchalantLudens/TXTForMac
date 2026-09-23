import AppKit
import Foundation

/// 查找/替换/转到行的会话状态与命令（T-017/T-018/T-019）。
@MainActor
@Observable
final class FindSession {
    var query = ""
    var replacement = ""
    var lineText = ""

    var caseSensitive = false
    var wholeWord = false
    var isRegex = false

    private(set) var matchCount = 0
    private(set) var currentIndex: Int?
    private(set) var isInvalidQuery = false

    /// 供 UI 显示的计数文案键
    var countDescription: String {
        if isInvalidQuery {
            return LocalizationSnapshot.string("find.invalidQuery")
        }
        guard matchCount > 0 else { return LocalizationSnapshot.string("find.noMatches") }
        if let currentIndex {
            return String(
                format: LocalizationSnapshot.string("find.matchIndex"),
                currentIndex + 1, matchCount
            )
        }
        return String(format: LocalizationSnapshot.string("find.matchTotal"), matchCount)
    }

    func updateMatches(in text: String) {
        do {
            let ranges = try TextSearch.matches(of: query, in: text, options: options)
            setMatchCount(ranges.count)
            if let currentIndex, currentIndex >= ranges.count {
                setCurrentIndex(ranges.isEmpty ? nil : 0)
            }
            setInvalid(false)
        } catch {
            setMatchCount(0)
            setCurrentIndex(nil)
            setInvalid(!query.isEmpty)
        }
    }

    // MARK: 供 Workspace 扩展使用的变更入口

    func setMatchCount(_ count: Int) {
        matchCount = count
    }

    func setCurrentIndex(_ index: Int?) {
        currentIndex = index
    }

    func setInvalid(_ invalid: Bool) {
        isInvalidQuery = invalid
    }

    var options: TextSearch.Options {
        TextSearch.Options(
            caseSensitive: caseSensitive,
            wholeWord: wholeWord,
            isRegex: isRegex
        )
    }

    func reset() {
        matchCount = 0
        currentIndex = nil
        isInvalidQuery = false
    }
}

extension Workspace {
    enum FindMode: Equatable {
        case find
        case replace
        case goToLine
    }

    var findBarIsVisible: Bool {
        findMode != nil
    }

    func beginFind() {
        findMode = .find
        refreshFindMatches()
    }

    func beginReplace() {
        findMode = .replace
        refreshFindMatches()
    }

    func beginGoToLine() {
        findMode = .goToLine
    }

    func hideFindBar() {
        findMode = nil
        store.currentDocument?.textView?.window?.makeFirstResponder(
            store.currentDocument?.textView
        )
    }

    /// 在当前文档中查找下一个/上一个匹配并选中显示。
    func findNext(direction: Int = 1) {
        guard let document = store.currentDocument, let textView = document.textView else { return }
        let text = document.text
        do {
            let ranges = try TextSearch.matches(
                of: find.query, in: text, options: find.options
            )
            find.setMatchCount(ranges.count)
            find.setInvalid(false)
            guard !ranges.isEmpty else {
                find.setCurrentIndex(nil)
                return
            }
            let selection = textView.selectedRange()
            let current: Int
            if direction > 0 {
                current = ranges.firstIndex { $0.location >= selection.location + selection.length } ?? 0
            } else {
                let before = ranges.lastIndex { $0.location < selection.location }
                current = before ?? ranges.count - 1
            }
            find.setCurrentIndex(current)
            let range = ranges[current]
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        } catch {
            find.setInvalid(true)
            find.setMatchCount(0)
        }
    }

    /// 替换当前匹配并移动到下一个。
    func replaceCurrent() {
        guard let document = store.currentDocument,
              let textView = document.textView,
              textView.isEditable else { return }
        let selection = textView.selectedRange()
        let nsText = document.text as NSString
        guard selection.location + selection.length <= nsText.length else { return }
        let matched = nsText.substring(with: selection)
        do {
            let replaced = try TextSearch.replacing(
                matched,
                query: find.query,
                template: find.replacement,
                options: find.options
            )
            textView.insertText(replaced, replacementRange: selection)
            document.noteUserEdit()
            findNext(direction: 1)
        } catch {
            find.setInvalid(true)
        }
    }

    /// 全部替换；可整体撤销（通过文本视图的撤销栈）。
    func replaceAll() {
        guard let document = store.currentDocument,
              let textView = document.textView,
              textView.isEditable else { return }
        do {
            let ranges = try TextSearch.matches(
                of: find.query, in: document.text, options: find.options
            )
            guard !ranges.isEmpty else { return }
            let nsText = document.text as NSString
            textView.undoManager?.beginUndoGrouping()
            for range in ranges.reversed() {
                let matched = nsText.substring(with: range)
                let replaced = try TextSearch.replacing(
                    matched,
                    query: find.query,
                    template: find.replacement,
                    options: find.options
                )
                textView.insertText(replaced, replacementRange: range)
            }
            textView.undoManager?.endUndoGrouping()
            document.noteUserEdit()
            find.setMatchCount(0)
            find.setCurrentIndex(nil)
            refreshStatusMetrics()
        } catch {
            find.setInvalid(true)
        }
    }

    func refreshFindMatches() {
        guard findBarIsVisible, findMode != .goToLine else { return }
        find.updateMatches(in: store.currentDocument?.text ?? "")
    }

    /// 转到行（T-019）：跳转后选中该行并滚动可见。
    func goToLine() {
        guard let document = store.currentDocument, let textView = document.textView else { return }
        defer { hideFindBar() }
        guard let line = Int(find.lineText.trimmingCharacters(in: .whitespaces)), line >= 1 else {
            presentError(GoToLineError.invalidInput)
            return
        }
        let text = document.text as NSString
        guard let range = Self.range(ofLine: line, in: text) else {
            presentError(GoToLineError.outOfRange(line))
            return
        }
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)
    }

    enum GoToLineError: LocalizedError, Equatable {
        case invalidInput
        case outOfRange(Int)

        var errorDescription: String? {
            switch self {
            case .invalidInput:
                LocalizationSnapshot.string("goto.invalidInput")
            case let .outOfRange(line):
                String(
                    format: LocalizationSnapshot.string("goto.outOfRange"),
                    line
                )
            }
        }
    }

    /// 行号（1 起）→ 该行行首的 UTF-16 区间；越界返回 nil。
    static func range(ofLine line: Int, in text: NSString) -> NSRange? {
        var currentLine = 1
        var lineStart = 0
        var lineEnd: Int?
        let length = text.length
        var index = 0
        while index < length {
            if currentLine == line {
                // 继续扫描至行尾
                var end = index
                while end < length {
                    let character = text.character(at: end)
                    if character == 0x0A {
                        // 处理 CRLF：去掉行尾 CR
                        if end > lineStart, text.character(at: end - 1) == 0x0D {
                            end -= 1
                        }
                        break
                    }
                    end += 1
                }
                lineEnd = end
                break
            }
            if text.character(at: index) == 0x0A {
                currentLine += 1
                lineStart = index + 1
            }
            index += 1
        }
        guard currentLine == line else { return nil }
        let start = lineStart
        let end = lineEnd ?? length
        return NSRange(location: start, length: max(end - start, 0))
    }
}
