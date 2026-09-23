import FinderSync

/// Finder 右键扩展（T-039..T-041/T-043）。
///
/// 与主 App 不用 App Group（ADR-002）：直接读同一份 `config.json`，
/// 并监听 `DistributedNotificationCenter` 的变更广播做热重载。
final class FinderSync: FIFinderSync {
    private let center = DistributedNotificationCenter.default()
    private var cachedSettings = AppSettings.default
    private var lastConfigModificationDate: Date?

    override init() {
        super.init()
        reloadConfiguration()
        center.addObserver(
            self,
            selector: #selector(configurationDidChange),
            name: Notification.Name(SettingsSchema.didChangeNotificationName),
            object: nil
        )
    }

    deinit {
        center.removeObserver(self)
    }

    // MARK: - 配置

    @objc
    private func configurationDidChange() {
        reloadConfiguration()
    }

    /// 重新读取配置并同步监控目录；mtime 未变化时跳过（T-043）。
    private func reloadConfiguration() {
        let url = SettingsLocation.defaultFileURL()
        let modificationDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate
        if let modificationDate, modificationDate == lastConfigModificationDate {
            return
        }
        lastConfigModificationDate = modificationDate

        if let data = try? Data(contentsOf: url),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            cachedSettings = settings
        } else {
            cachedSettings = .default
        }
        applyMonitoredDirectories()
    }

    /// 空配置回落到桌面/文稿/下载（AppSettings 契约）。
    private func applyMonitoredDirectories() {
        let paths = monitoredDirectoryPaths()
        FIFinderSyncController.default().directoryURLs = Set(paths.map { URL(fileURLWithPath: $0, isDirectory: true) })
    }

    private func monitoredDirectoryPaths() -> [String] {
        if cachedSettings.finderMonitoredDirectories.isEmpty {
            return defaultMonitoredPaths()
        }
        return cachedSettings.finderMonitoredDirectories
    }

    private func defaultMonitoredPaths() -> [String] {
        let fileManager = FileManager.default
        let directories: [FileManager.SearchPathDirectory] = [
            .desktopDirectory,
            .documentDirectory,
            .downloadsDirectory,
        ]
        return directories.compactMap {
            fileManager.urls(for: $0, in: .userDomainMask).first?.path
        }
    }

    // MARK: - 右键菜单

    override func menu(for _: FIMenuKind) -> NSMenu {
        reloadConfiguration()
        guard cachedSettings.finderExtensionEnabled else { return NSMenu(title: "") }

        let title = cachedSettings.finderMenuItemTitle.isEmpty
            ? LocalizationSnapshot.string("finder.menuTitle")
            : cachedSettings.finderMenuItemTitle
        let item = NSMenuItem(
            title: title,
            action: #selector(createTextFile(_:)),
            keyEquivalent: ""
        )
        item.target = self
        let menu = NSMenu(title: title)
        menu.addItem(item)
        return menu
    }

    // MARK: - 新建文件

    @objc
    private func createTextFile(_: NSMenuItem) {
        guard let directory = targetDirectory() else { return }
        let settings = cachedSettings
        let fileName = FileNaming.availableFileName(
            base: settings.defaultNewFileName,
            ext: settings.finderNewFileExtension,
            in: directory,
            policy: settings.finderNamingConflictPolicy
        )
        let fileURL = directory.appendingPathComponent(fileName)
        let content = settings.finderTemplateContent
        let lineEnding = settings.defaultLineEnding
        let payload = lineEnding.applying(to: content)
        guard let data = settings.defaultEncoding.encode(payload) else { return }
        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
        openInMainApp(fileURL)
    }

    /// 菜单触发的目标目录：容器菜单用 targetedURL；条目菜单用选中项所在目录。
    private func targetDirectory() -> URL? {
        let controller = FIFinderSyncController.default()
        if let targeted = controller.targetedURL() {
            return targeted
        }
        if let selected = controller.selectedItemURLs()?.first {
            return selected.deletingLastPathComponent()
        }
        return nil
    }

    /// 用主 App 打开新建文件（未运行时由 LaunchServices 拉起）。
    private func openInMainApp(_ fileURL: URL) {
        let appURL = containingAppURL() ?? Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration)
    }

    /// 从 `…/TXTForMac.app/Contents/PlugIns/TXTForMacFinder.appex` 反推主 App 地址。
    private func containingAppURL() -> URL? {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "appex" else { return nil }
        return bundleURL.deletingLastPathComponent().deletingLastPathComponent()
    }
}

/// 扩展端文案：不走 LocalizationService（那依赖主 App 的语言设置），
/// 直接按系统语言读主 App 包内的 Localizable.strings。
private enum LocalizationSnapshot {
    static func string(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}
