import SwiftUI

/// 应用入口。
///
/// 窗口内容由 `WindowRootView` 提供；主菜单经 `AppCommands` 生成；
/// 全局服务（配置、语言）在首次访问 `SettingsStore.shared` /
/// `LocalizationService.shared` 时初始化。
@main
struct TXTForMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
        .commands {
            AppCommands()
        }
    }
}

/// AppKit 生命周期挂点：注册服务提供者等（M5 扩展）。
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidBecomeActive(_: Notification) {
        // SwiftUI 菜单栏就绪后注入「打开最近文件」子菜单
        DispatchQueue.main.async {
            RecentFilesMenuController.shared.installIfNeeded()
        }
    }
}
