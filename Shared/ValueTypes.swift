import Foundation

// 配置项使用的受约束取值类型。
//
// 编码与换行符的可编码模型已升级为 `Shared/TextEncoding` 与 `Shared/LineEnding`
// （T-005/T-006），其原始值与这里的标识拼写一致，config.json 无需迁移。
// 本文件只承载与编码无关的行为偏好。

/// 界面语言。
public enum AppLanguage: String, Codable, Sendable, CaseIterable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
}

/// 启动行为。
public enum LaunchBehavior: String, Codable, Sendable, CaseIterable {
    case blankDocument
    case restoreLastSession
    case recentFiles
}

/// 外观主题。
public enum ThemePreference: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

/// 更新检查频率。
public enum CheckUpdateFrequency: String, Codable, Sendable, CaseIterable {
    case daily
    case weekly
    case monthly
    case never
}

/// 更新通道。
public enum UpdateChannel: String, Codable, Sendable, CaseIterable {
    case stable
    case preview
}

/// Finder 新建文件命名冲突策略。
public enum NamingConflictPolicy: String, Codable, Sendable, CaseIterable {
    case autoNumber
    case duplicateCopy
    case ask
}
