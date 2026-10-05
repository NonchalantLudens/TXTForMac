import AppKit
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
        Settings {
            SettingsRootView()
        }
    }
}

/// AppKit 生命周期挂点：文档打开事件、快速操作服务与最近文件菜单。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        NSApp.servicesProvider = self
    }

    func applicationDidBecomeActive(_: Notification) {
        // SwiftUI 菜单栏就绪后注入「打开最近文件」子菜单
        DispatchQueue.main.async {
            RecentFilesMenuController.shared.installIfNeeded()
        }
    }

    /// 文档打开事件（Finder 双击 / 打开方式 / 拖到 Dock 图标）统一在此接管：
    /// 比 SwiftUI 的 onOpenURL 更可靠，后者对启动期事件可能不触发。
    func application(_: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            OpenRequestQueue.shared.enqueue(urls)
        }
    }

    /// 快速操作兜底（T-042）：Finder 未监控目录也能从右键「快速操作」新建文本文件。
    @objc
    func newTextFileHere(_ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer) {
        guard let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], let folder = urls.first else { return }

        Task { @MainActor in
            self.createTextFile(in: folder)
        }
    }

    @MainActor
    private func createTextFile(in folder: URL) {
        let settings = SettingsStore.shared.settings
        // 服务端无 UI，「每次询问」策略退化为自动编号，创建后由用户改名
        let fileName = FileNaming.availableFileName(
            base: settings.defaultNewFileName,
            ext: settings.finderNewFileExtension,
            in: folder,
            policy: .autoNumber
        )
        let fileURL = folder.appendingPathComponent(fileName)
        let payload = settings.defaultLineEnding.applying(to: settings.finderTemplateContent)
        guard let data = settings.defaultEncoding.encode(payload) else { return }
        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            NSApp.presentError(error)
            return
        }
        if let workspace = WorkspaceRegistry.shared.active {
            workspace.open(url: fileURL)
        } else {
            NSWorkspace.shared.open(fileURL)
        }
    }
}
