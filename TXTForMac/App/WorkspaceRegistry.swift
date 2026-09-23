import AppKit

/// 窗口 ↔ Workspace 注册表：供菜单兜底命令（最近文件等）定位当前 key window。
@MainActor
final class WorkspaceRegistry {
    static let shared = WorkspaceRegistry()

    private let map = NSMapTable<NSWindow, Workspace>(keyOptions: .weakMemory, valueOptions: .weakMemory)

    private init() {}

    func register(_ workspace: Workspace, for window: NSWindow) {
        map.setObject(workspace, forKey: window)
    }

    func unregister(window: NSWindow) {
        map.removeObject(forKey: window)
    }

    var active: Workspace? {
        guard let keyWindow = NSApp.keyWindow ?? NSApp.mainWindow else { return nil }
        return map.object(forKey: keyWindow) ?? all.first
    }

    var all: [Workspace] {
        guard let enumerator = map.objectEnumerator() else { return [] }
        return enumerator.allObjects.compactMap { $0 as? Workspace }
    }
}

/// 「打开最近文件」菜单（T-024）：注入 SwiftUI 生成的文件菜单，动态刷新。
@MainActor
final class RecentFilesMenuController: NSObject, NSMenuDelegate {
    static let shared = RecentFilesMenuController()

    private var installed = false
    private let submenuIdentifier = NSUserInterfaceItemIdentifier("txtformac.recentFiles")

    /// 在应用激活后调用；菜单未就绪时静默等待下次机会。
    func installIfNeeded() {
        guard !installed,
              let fileMenu = NSApp.mainMenu?.items.first?.submenu else { return }
        guard fileMenu.items.first(where: { $0.submenu?.identifier == submenuIdentifier }) == nil,
              let openIndex = fileMenu.items.firstIndex(where: { $0.keyEquivalent == "o" })
        else {
            installed = fileMenu.items.contains { $0.submenu?.identifier == submenuIdentifier }
            return
        }
        let recentItem = NSMenuItem(
            title: LocalizationSnapshot.string("menu.file.openRecent"),
            action: nil,
            keyEquivalent: ""
        )
        let submenu = NSMenu(title: recentItem.title)
        submenu.identifier = submenuIdentifier
        submenu.delegate = self
        recentItem.submenu = submenu
        fileMenu.insertItem(recentItem, at: openIndex + 1)
        installed = true
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let recents = SettingsStore.shared.settings.recentFiles
        let hasActiveWorkspace = WorkspaceRegistry.shared.active != nil
        if recents.isEmpty {
            let empty = NSMenuItem(
                title: LocalizationSnapshot.string("menu.file.openRecent.empty"),
                action: nil,
                keyEquivalent: ""
            )
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }
        for path in recents {
            let item = NSMenuItem(
                title: (path as NSString).lastPathComponent,
                action: #selector(openRecentFile(_:)),
                keyEquivalent: ""
            )
            item.representedObject = path
            item.toolTip = path
            item.isEnabled = hasActiveWorkspace
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let clear = NSMenuItem(
            title: LocalizationSnapshot.string("menu.file.openRecent.clear"),
            action: #selector(clearRecentFiles(_:)),
            keyEquivalent: ""
        )
        clear.target = self
        menu.addItem(clear)
    }

    @objc
    private func openRecentFile(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        WorkspaceRegistry.shared.active?.open(url: URL(fileURLWithPath: path))
    }

    @objc
    private func clearRecentFiles(_: NSMenuItem) {
        SettingsStore.shared.update { settings in
            settings.recentFiles = []
        }
    }
}
