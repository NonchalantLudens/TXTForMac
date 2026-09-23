import Foundation
import os

/// 设置变更广播的抽象：主 App 侧默认走系统分布式通知，测试可注入替身。
protocol SettingsChangeBroadcaster: Sendable {
    func postChange()
}

/// 把配置变更广播给 Finder 扩展（ADR-002：不用 App Group，靠通知 + 同一份 JSON）。
struct DistributedSettingsBroadcaster: SettingsChangeBroadcaster {
    func postChange() {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(SettingsSchema.didChangeNotificationName),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}

/// 全部设置读写的唯一入口（ADR-004）。
///
/// - 落盘为原子写，任何一次写入失败都不产生半截 JSON
/// - 配置缺失回落默认值并创建文件；损坏文件先备份（`config.corrupt-<时间戳>`）再重建
/// - `update` 在值真正变化时写盘并广播，供 Finder 扩展热重载
@MainActor
@Observable
final class SettingsStore {
    private(set) var settings: AppSettings

    private let fileURL: URL
    private let broadcaster: SettingsChangeBroadcaster
    private let fileManager: FileManager

    private static let logger = Logger(
        subsystem: "online.nonchalantludens.txtformac",
        category: "SettingsStore"
    )

    /// - Parameters:
    ///   - fileURL: 配置文件地址；nil 时使用应用支持目录下的默认位置
    ///   - broadcaster: 变更广播器
    init(
        fileURL: URL? = nil,
        broadcaster: SettingsChangeBroadcaster = DistributedSettingsBroadcaster(),
        fileManager: FileManager = .default
    ) {
        let resolvedURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.fileURL = resolvedURL
        self.broadcaster = broadcaster
        self.fileManager = fileManager

        let loaded = Self.load(fileURL: resolvedURL, fileManager: fileManager)
        settings = loaded.settings
        if loaded.needsPersist {
            Self.persist(settings, to: resolvedURL, fileManager: fileManager)
        }
    }

    /// 修改设置；值真正变化时写盘并广播。
    func update(_ mutate: (inout AppSettings) -> Void) {
        var next = settings
        mutate(&next)
        guard next != settings else { return }
        settings = next
        Self.persist(settings, to: fileURL, fileManager: fileManager)
        broadcaster.postChange()
    }

    /// 重新从磁盘读取（例如收到另一进程的变更通知时）。
    func reload() {
        let loaded = Self.load(fileURL: fileURL, fileManager: fileManager)
        settings = loaded.settings
    }

    /// 把语言选择镜像到系统偏好。
    ///
    /// 应用内文案由 `LocalizationService` 即时切换；系统级界面（如打开面板）读取
    /// `AppleLanguages`，需下次启动对齐。跟随系统时移除覆盖。
    func syncSystemLanguagePreference(_ language: AppLanguage, defaults: UserDefaults = .standard) {
        switch language {
        case .system:
            defaults.removeObject(forKey: SettingsSchema.systemLanguageOverrideKey)
        case .english, .simplifiedChinese:
            defaults.set([language.rawValue], forKey: SettingsSchema.systemLanguageOverrideKey)
        }
    }

    /// 默认配置文件地址：`~/Library/Application Support/TXTForMac/config.json`。
    static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        return supportDirectory
            .appendingPathComponent(SettingsSchema.directoryName, isDirectory: true)
            .appendingPathComponent(SettingsSchema.fileName)
    }

    // MARK: - 读取

    private static func load(
        fileURL: URL,
        fileManager: FileManager
    ) -> (settings: AppSettings, needsPersist: Bool) {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return (AppSettings.default, true)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            var settings = try JSONDecoder().decode(AppSettings.self, from: data)
            // 迁移语义：字段已按当前结构解码完成，因此把历史版本号归一到当前版本，
            // 避免旧版本号被原样写回、后续迁移再次误判。
            settings.schemaVersion = SettingsSchema.schemaVersion
            return (settings, false)
        } catch {
            logger.error("配置文件解析失败，已备份并回落默认值：\(error.localizedDescription, privacy: .public)")
            backupCorruptFile(at: fileURL, fileManager: fileManager)
            return (AppSettings.default, true)
        }
    }

    private static func backupCorruptFile(at fileURL: URL, fileManager: FileManager) {
        let timestamp = Int(Date.now.timeIntervalSince1970)
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("\(SettingsSchema.corruptBackupPrefix)\(timestamp).json")
        try? fileManager.removeItem(at: backupURL)
        try? fileManager.moveItem(at: fileURL, to: backupURL)
    }

    // MARK: - 写入

    private static func persist(
        _ settings: AppSettings,
        to fileURL: URL,
        fileManager: FileManager
    ) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.error("配置写盘失败：\(error.localizedDescription, privacy: .public)")
        }
    }
}
