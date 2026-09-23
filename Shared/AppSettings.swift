import Foundation

/// 全部用户设置的值类型（US-007 设置项清单的唯一载体）。
///
/// 解码策略（ADR-004）：字段缺失回落默认值、未知字段忽略、历史 `schemaVersion` 可加载，
/// 保证 config.json 向前兼容；损坏文件由 `SettingsStore` 备份后重建。
struct AppSettings: Codable, Equatable, Sendable {
    // MARK: 通用

    var interfaceLanguage: AppLanguage = .system
    var launchBehavior: LaunchBehavior = .restoreLastSession
    var defaultNewFileName: String = "Untitled"
    var defaultFileExtension: String = "txt"
    var defaultEncoding: EncodingIdentifier = .utf8
    var defaultLineEnding: LineEndingIdentifier = .lf

    // MARK: 编辑

    /// 空字符串表示使用系统等宽字体
    var editorFontFamily: String = ""
    var editorUseMonospacedFont: Bool = true
    var editorFontSize: Double = 13
    var editorLineSpacing: Double = 0
    var tabWidth: Int = 4
    var useSoftTabs: Bool = true
    var autoIndent: Bool = true
    var defaultWordWrap: Bool = true
    var rememberZoomPerDocument: Bool = true
    var pasteWithoutFormatting: Bool = false

    // MARK: 文件

    var autoSaveEnabled: Bool = true
    var autoSaveIntervalSeconds: Int = 10
    var saveSessionOnClose: Bool = true
    var recentFilesLimit: Int = 10
    var largeFileWarningThresholdBytes: Int = 20 * ByteCount.megabyte
    var readOnlyThresholdBytes: Int = 100 * ByteCount.megabyte
    var createBackupFile: Bool = false

    // MARK: 外观

    var theme: ThemePreference = .system
    var showTabBar: Bool = true
    var showStatusBar: Bool = true
    /// 用户覆盖的编辑器背景色（hex），nil 表示跟随 Color Set（ADR-006）
    var editorBackgroundHex: String?
    /// 用户覆盖的编辑器前景色（hex），nil 表示跟随 Color Set（ADR-006）
    var editorForegroundHex: String?

    // MARK: 右键集成

    var finderExtensionEnabled: Bool = true
    /// 监控目录绝对路径；为空表示使用默认三目录（桌面/文稿/下载），在读取端解析
    var finderMonitoredDirectories: [String] = []
    /// 空字符串表示使用本地化默认标题
    var finderMenuItemTitle: String = ""
    var finderNewFileExtension: String = "txt"
    var finderTemplateContent: String = ""
    var finderNamingConflictPolicy: NamingConflictPolicy = .autoNumber

    // MARK: 更新

    var updateCheckFrequency: CheckUpdateFrequency = .daily
    var updateChannel: UpdateChannel = .stable

    // MARK: 结构版本

    /// 读入历史配置时可能小于 `SettingsSchema.schemaVersion`
    var schemaVersion: Int = SettingsSchema.schemaVersion

    /// 默认配置。
    static let `default` = AppSettings()

    /// 同文件扩展中的自定义 `init(from:)` 会抑制编译器合成的逐成员初始化器，
    /// 这里显式补上「全默认值」初始化器。
    init() {}

    private enum CodingKeys: String, CodingKey {
        case interfaceLanguage
        case launchBehavior
        case defaultNewFileName
        case defaultFileExtension
        case defaultEncoding
        case defaultLineEnding
        case editorFontFamily
        case editorUseMonospacedFont
        case editorFontSize
        case editorLineSpacing
        case tabWidth
        case useSoftTabs
        case autoIndent
        case defaultWordWrap
        case rememberZoomPerDocument
        case pasteWithoutFormatting
        case autoSaveEnabled
        case autoSaveIntervalSeconds
        case saveSessionOnClose
        case recentFilesLimit
        case largeFileWarningThresholdBytes
        case readOnlyThresholdBytes
        case createBackupFile
        case theme
        case showTabBar
        case showStatusBar
        case editorBackgroundHex
        case editorForegroundHex
        case finderExtensionEnabled
        case finderMonitoredDirectories
        case finderMenuItemTitle
        case finderNewFileExtension
        case finderTemplateContent
        case finderNamingConflictPolicy
        case updateCheckFrequency
        case updateChannel
        case schemaVersion
    }

    /// 逐字段 `decodeIfPresent`：缺失字段回落默认值，未知字段被 JSONDecoder 忽略。
    init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try Self.decodeGeneral(into: &self, from: container)
        try Self.decodeEditing(into: &self, from: container)
        try Self.decodeFiles(into: &self, from: container)
        try Self.decodeAppearance(into: &self, from: container)
        try Self.decodeFinder(into: &self, from: container)
        try Self.decodeUpdate(into: &self, from: container)

        schemaVersion = try container.decodeIfPresent(
            Int.self, forKey: .schemaVersion
        ) ?? schemaVersion
    }

    // MARK: - 分组解码

    private static func decodeGeneral(
        into target: inout AppSettings,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws {
        target.interfaceLanguage = try container.decodeIfPresent(
            AppLanguage.self, forKey: .interfaceLanguage
        ) ?? target.interfaceLanguage
        target.launchBehavior = try container.decodeIfPresent(
            LaunchBehavior.self, forKey: .launchBehavior
        ) ?? target.launchBehavior
        target.defaultNewFileName = try container.decodeIfPresent(
            String.self, forKey: .defaultNewFileName
        ) ?? target.defaultNewFileName
        target.defaultFileExtension = try container.decodeIfPresent(
            String.self, forKey: .defaultFileExtension
        ) ?? target.defaultFileExtension
        target.defaultEncoding = try container.decodeIfPresent(
            EncodingIdentifier.self, forKey: .defaultEncoding
        ) ?? target.defaultEncoding
        target.defaultLineEnding = try container.decodeIfPresent(
            LineEndingIdentifier.self, forKey: .defaultLineEnding
        ) ?? target.defaultLineEnding
    }

    private static func decodeEditing(
        into target: inout AppSettings,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws {
        target.editorFontFamily = try container.decodeIfPresent(
            String.self, forKey: .editorFontFamily
        ) ?? target.editorFontFamily
        target.editorUseMonospacedFont = try container.decodeIfPresent(
            Bool.self, forKey: .editorUseMonospacedFont
        ) ?? target.editorUseMonospacedFont
        target.editorFontSize = try container.decodeIfPresent(
            Double.self, forKey: .editorFontSize
        ) ?? target.editorFontSize
        target.editorLineSpacing = try container.decodeIfPresent(
            Double.self, forKey: .editorLineSpacing
        ) ?? target.editorLineSpacing
        target.tabWidth = try container.decodeIfPresent(
            Int.self, forKey: .tabWidth
        ) ?? target.tabWidth
        target.useSoftTabs = try container.decodeIfPresent(
            Bool.self, forKey: .useSoftTabs
        ) ?? target.useSoftTabs
        target.autoIndent = try container.decodeIfPresent(
            Bool.self, forKey: .autoIndent
        ) ?? target.autoIndent
        target.defaultWordWrap = try container.decodeIfPresent(
            Bool.self, forKey: .defaultWordWrap
        ) ?? target.defaultWordWrap
        target.rememberZoomPerDocument = try container.decodeIfPresent(
            Bool.self, forKey: .rememberZoomPerDocument
        ) ?? target.rememberZoomPerDocument
        target.pasteWithoutFormatting = try container.decodeIfPresent(
            Bool.self, forKey: .pasteWithoutFormatting
        ) ?? target.pasteWithoutFormatting
    }

    private static func decodeFiles(
        into target: inout AppSettings,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws {
        target.autoSaveEnabled = try container.decodeIfPresent(
            Bool.self, forKey: .autoSaveEnabled
        ) ?? target.autoSaveEnabled
        target.autoSaveIntervalSeconds = try container.decodeIfPresent(
            Int.self, forKey: .autoSaveIntervalSeconds
        ) ?? target.autoSaveIntervalSeconds
        target.saveSessionOnClose = try container.decodeIfPresent(
            Bool.self, forKey: .saveSessionOnClose
        ) ?? target.saveSessionOnClose
        target.recentFilesLimit = try container.decodeIfPresent(
            Int.self, forKey: .recentFilesLimit
        ) ?? target.recentFilesLimit
        target.largeFileWarningThresholdBytes = try container.decodeIfPresent(
            Int.self, forKey: .largeFileWarningThresholdBytes
        )
            ?? target.largeFileWarningThresholdBytes
        target.readOnlyThresholdBytes = try container.decodeIfPresent(
            Int.self, forKey: .readOnlyThresholdBytes
        ) ?? target.readOnlyThresholdBytes
        target.createBackupFile = try container.decodeIfPresent(
            Bool.self, forKey: .createBackupFile
        ) ?? target.createBackupFile
    }

    private static func decodeAppearance(
        into target: inout AppSettings,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws {
        target.theme = try container.decodeIfPresent(
            ThemePreference.self, forKey: .theme
        ) ?? target.theme
        target.showTabBar = try container.decodeIfPresent(
            Bool.self, forKey: .showTabBar
        ) ?? target.showTabBar
        target.showStatusBar = try container.decodeIfPresent(
            Bool.self, forKey: .showStatusBar
        ) ?? target.showStatusBar
        target.editorBackgroundHex = try container.decodeIfPresent(
            String.self, forKey: .editorBackgroundHex
        )
        target.editorForegroundHex = try container.decodeIfPresent(
            String.self, forKey: .editorForegroundHex
        )
    }

    private static func decodeFinder(
        into target: inout AppSettings,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws {
        target.finderExtensionEnabled = try container.decodeIfPresent(
            Bool.self, forKey: .finderExtensionEnabled
        ) ?? target.finderExtensionEnabled
        target.finderMonitoredDirectories = try container.decodeIfPresent(
            [String].self, forKey: .finderMonitoredDirectories
        )
            ?? target.finderMonitoredDirectories
        target.finderMenuItemTitle = try container.decodeIfPresent(
            String.self, forKey: .finderMenuItemTitle
        ) ?? target.finderMenuItemTitle
        target.finderNewFileExtension = try container.decodeIfPresent(
            String.self, forKey: .finderNewFileExtension
        ) ?? target.finderNewFileExtension
        target.finderTemplateContent = try container.decodeIfPresent(
            String.self, forKey: .finderTemplateContent
        ) ?? target.finderTemplateContent
        target.finderNamingConflictPolicy = try container.decodeIfPresent(
            NamingConflictPolicy.self, forKey: .finderNamingConflictPolicy
        )
            ?? target.finderNamingConflictPolicy
    }

    private static func decodeUpdate(
        into target: inout AppSettings,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws {
        target.updateCheckFrequency = try container.decodeIfPresent(
            CheckUpdateFrequency.self, forKey: .updateCheckFrequency
        )
            ?? target.updateCheckFrequency
        target.updateChannel = try container.decodeIfPresent(
            UpdateChannel.self, forKey: .updateChannel
        ) ?? target.updateChannel
    }
}
