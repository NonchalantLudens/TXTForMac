import SwiftUI

/// 主窗口根视图。
///
/// M0 阶段呈现双语应用标识（同时验证语言切换链路）；T-012 起在此逐步长出
/// 编辑器外壳（标签栏 → 编辑器 → 状态栏）。
struct WindowRootView: View {
    /// 最小窗口尺寸，对齐 devplaybook/PROJECT/UI_STYLE.md。
    static let minimumWindowSize = CGSize(width: 480, height: 320)

    @State private var localization = LocalizationService.shared

    var body: some View {
        VStack(spacing: UIConstants.spacingStandard) {
            Text(localization.string("app.name"))
                .font(.headline)
            Text(localization.string("app.tagline"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(
            minWidth: Self.minimumWindowSize.width,
            maxWidth: .infinity,
            minHeight: Self.minimumWindowSize.height,
            maxHeight: .infinity
        )
    }
}

/// 间距 token（UI_STYLE「间距与圆角」），视图内禁止散落魔法数字。
enum UIConstants {
    static let spacingCompact: CGFloat = 6
    static let spacingStandard: CGFloat = 12
    static let spacingLoose: CGFloat = 20
    static let cornerRadiusControl: CGFloat = 6
    static let cornerRadiusPanel: CGFloat = 10
}
