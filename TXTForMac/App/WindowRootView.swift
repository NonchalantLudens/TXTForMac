import SwiftUI

/// 主窗口根视图。
///
/// 当前只承担窗口尺寸约束与最小内容；T-012 起在此逐步长出编辑器外壳
/// （标签栏 → 编辑器 → 状态栏）。为避免出现无归属的占位实现，本视图不预置
/// 未实现的功能入口。
struct WindowRootView: View {
    /// 最小窗口尺寸，对齐 devplaybook/PROJECT/UI_STYLE.md。
    static let minimumWindowSize = CGSize(width: 480, height: 320)

    var body: some View {
        Color.clear
            .frame(
                minWidth: Self.minimumWindowSize.width,
                minHeight: Self.minimumWindowSize.height
            )
    }
}
