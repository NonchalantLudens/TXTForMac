import SwiftUI

/// 应用入口。
///
/// M0 阶段只提供窗口外壳；编辑器内核（`EditorController`）、主菜单与标签栏
/// 在同一分支的后续任务中挂载到 `WindowRootView`。
@main
struct TXTForMacApp: App {
    /// 默认窗口尺寸，对齐 devplaybook/PROJECT/UI_STYLE.md 的设计基调。
    static let defaultWindowSize = CGSize(width: 900, height: 600)

    var body: some Scene {
        WindowGroup {
            WindowRootView()
        }
        .defaultSize(
            width: Self.defaultWindowSize.width,
            height: Self.defaultWindowSize.height
        )
    }
}
