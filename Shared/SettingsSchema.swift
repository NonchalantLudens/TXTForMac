import Foundation

/// 配置文件与进程间广播的键名唯一来源（ADR-002 / ADR-004）。
///
/// 主 App 与 Finder 扩展共用本文件；禁止在其它文件散落书写这些字符串。
public enum SettingsSchema {
    /// 配置目录名（位于 `~/Library/Application Support/` 下）
    public static let directoryName = "TXTForMac"

    /// 配置文件名
    public static let fileName = "config.json"

    /// 当前配置结构版本；新增或变更字段时递增
    public static let schemaVersion = 1

    /// 损坏配置的备份文件名前缀
    public static let corruptBackupPrefix = "config.corrupt-"

    /// 配置变更广播名（经 `DistributedNotificationCenter` 发往 Finder 扩展）
    public static let didChangeNotificationName =
        "online.nonchalantludens.txtformac.settings.didChange"

    /// 系统级语言覆盖的偏好键（写入应用自身的 UserDefaults 域，下次启动对齐系统级界面）
    public static let systemLanguageOverrideKey = "AppleLanguages"
}

/// 字节数语义常量，避免阈值配置里出现魔法数字。
public enum ByteCount {
    public static let kilobyte = 1024
    public static let megabyte = 1_048_576

    /// 面向用户的可读格式（例如 1.5 MB）。
    public static func format(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
