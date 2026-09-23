import AppKit
import SwiftUI

/// 编辑器宿主：每个文档一个滚动视图（文本视图随文档实例走，切换标签时 SwiftUI 按 id 重建外壳）。
struct EditorScrollView: NSViewRepresentable {
    let document: Document
    let workspace: Workspace

    func makeNSView(context _: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = EditorTheme.background
        let textView = document.acquireTextView { workspace.makeTextView(for: $0) }
        scrollView.documentView = textView
        textView.isEditable = !document.isReadOnly
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context _: Context) {
        // 文本视图由文档模型持有；这里只在只读状态变化时同步
        (nsView.documentView as? NSTextView)?.isEditable = !document.isReadOnly
    }
}

/// 捕获所在 NSWindow 交给窗口模型（菜单命令与关闭确认需要它）。
struct WindowAccessor: NSViewRepresentable {
    let onBind: (NSWindow) -> Void

    func makeNSView(context _: Context) -> NSView {
        ProbeView(onBind: onBind)
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        guard let probe = nsView as? ProbeView, let window = probe.window else { return }
        probe.notifyWindowBound()
    }

    private final class ProbeView: NSView {
        let onBind: (NSWindow) -> Void
        private var boundID: ObjectIdentifier?

        init(onBind: @escaping (NSWindow) -> Void) {
            self.onBind = onBind
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("WindowAccessor 不支持从 nib 创建")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            notifyWindowBound()
        }

        func notifyWindowBound() {
            guard let window, boundID != ObjectIdentifier(window) else { return }
            boundID = ObjectIdentifier(window)
            onBind(window)
        }
    }
}
