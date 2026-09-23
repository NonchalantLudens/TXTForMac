import Foundation

// 配置项使用的受约束取值类型。
//
// 只承载「标识 ↔ 展示」的稳定契约；对应的检测与转换行为在 T-005/T-006 建立的模型里实现。
// 这些原始值会写入 config.json，因此一经发布不可改写拼写。

/// 界面语言。
public enum AppLanguage: String, Codable, Sendable, CaseIterable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
}

/// 文本编码标识（与 `String.Encoding` 的映射在 TextEncoding 模型中完成）。
public enum EncodingIdentifier: String, Codable, Sendable, CaseIterable {
    case utf8 = "utf-8"
    case utf8BOM = "utf-8-bom"
    case utf16LittleEndian = "utf-16le"
    case utf16BigEndian = "utf-16be"
    case gb18030
    case big5
    case shiftJIS = "shift-jis"
    case latin1 = "latin-1"
    case ascii
}

/// 换行符标识。
public enum LineEndingIdentifier: String, Codable, Sendable, CaseIterable {
    case lf
    case crlf
    case cr
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
