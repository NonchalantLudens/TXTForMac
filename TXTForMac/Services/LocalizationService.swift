import Foundation
import Observation

/// 运行时语言切换服务（US-010）。
///
/// 文案源仍是 `.lproj/Localizable.strings`；切换语言时按语言代码解析对应 `Bundle`
/// 并即时生效，同时把选择持久化进 `SettingsStore`（ADR-007）。
@MainActor
@Observable
final class LocalizationService {
    /// 应用级单例：读取真实配置文件。
    static let shared = LocalizationService()

    /// 当前生效语言
    private(set) var language: AppLanguage

    /// 当前文案解析所用 Bundle
    private(set) var bundle: Bundle

    private let settings: SettingsStore

    /// - Parameters:
    ///   - settings: 语言选择的持久化出口
    ///   - systemDefaults: 系统语言镜像写入的偏好域（测试注入）
    init(settings: SettingsStore = .shared, systemDefaults: UserDefaults = .standard) {
        self.settings = settings
        let stored = settings.settings.interfaceLanguage
        language = stored
        bundle = Self.bundle(for: stored)
        self.systemDefaults = systemDefaults
        LocalizationSnapshot.update(bundle)
    }

    private let systemDefaults: UserDefaults

    /// 切换语言：即时生效并持久化。
    func setLanguage(_ newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        language = newLanguage
        bundle = Self.bundle(for: newLanguage)
        LocalizationSnapshot.update(bundle)
        settings.update { $0.interfaceLanguage = newLanguage }
        settings.syncSystemLanguagePreference(newLanguage, defaults: systemDefaults)
    }

    /// 解析本地化文案；未知键回落键名本身。
    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// 解析带参数的本地化文案。
    func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }

    // MARK: - Bundle 解析

    private static func bundle(for language: AppLanguage) -> Bundle {
        switch language {
        case .system:
            preferredSystemBundle() ?? .main
        case .english, .simplifiedChinese:
            resourceBundle(forLanguageCode: language.rawValue) ?? .main
        }
    }

    private static func preferredSystemBundle() -> Bundle? {
        Locale.preferredLanguages.lazy
            .compactMap { resourceBundle(forLanguageCode: $0) }
            .first
    }

    /// 精确匹配语言代码；匹配不到时按前缀归并（如 `zh-Hans-CN` → `zh-Hans`）。
    private static func resourceBundle(forLanguageCode code: String) -> Bundle? {
        let available = Set(Bundle.main.localizations)
        let candidates = available
            .filter { localization in
                localization == code
                    || code.hasPrefix("\(localization)-")
                    || localization.hasPrefix("\(code)-")
            }
            .sorted { $0.count < $1.count }
        guard let match = candidates.first,
              let path = Bundle.main.path(forResource: match, ofType: "lproj")
        else {
            return nil
        }
        return Bundle(path: path)
    }
}

/// 供非隔离上下文（如错误展示可能发生在后台线程）使用的当前文案 Bundle 快照。
enum LocalizationSnapshot {
    private static let storage = Storage()

    /// 锁与可变状态内聚在一个 @unchecked Sendable 小对象里，
    /// 避免 nonisolated(unsafe) 全局可变存储（Swift 6 严格并发不欢迎）。
    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var bundle: Bundle = .main

        func current() -> Bundle {
            lock.lock()
            defer { lock.unlock() }
            return bundle
        }

        func update(_ newBundle: Bundle) {
            lock.lock()
            bundle = newBundle
            lock.unlock()
        }
    }

    static func update(_ newBundle: Bundle) {
        storage.update(newBundle)
    }

    static var current: Bundle {
        storage.current()
    }

    static func string(_ key: String) -> String {
        current.localizedString(forKey: key, value: key, table: nil)
    }
}

/// 本地化文案便捷入口。
enum L10n {
    @MainActor
    static func string(_ key: String) -> String {
        LocalizationService.shared.string(key)
    }

    @MainActor
    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        LocalizationService.shared.string(key, arguments)
    }
}
