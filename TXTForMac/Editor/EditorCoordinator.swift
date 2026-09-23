import AppKit

/// 文本视图代理：把用户编辑与选区变化转发给所属窗口模型。
@MainActor
final class EditorCoordinator: NSObject, NSTextViewDelegate {
    var onTextChange: (() -> Void)?
    var onSelectionChange: (() -> Void)?

    func textDidChange(_: Notification) {
        onTextChange?()
        onSelectionChange?()
    }

    func textViewDidChangeSelection(_: Notification) {
        onSelectionChange?()
    }
}
