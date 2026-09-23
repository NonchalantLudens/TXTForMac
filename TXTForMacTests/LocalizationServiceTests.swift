@testable import TXTForMac
import XCTest

/// 守护运行时语言切换契约（US-010）：即时生效、持久化、未知键回落。
@MainActor
final class LocalizationServiceTests: XCTestCase {
    private var tempDirectory: URL!
    private var suiteName: String!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("txtformac-localization-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func makeStore() -> SettingsStore {
        SettingsStore(
            fileURL: tempDirectory.appendingPathComponent(SettingsSchema.fileName),
            broadcaster: SpyBroadcaster()
        )
    }

    private func makeService(
        store: SettingsStore,
        defaults: UserDefaults
    ) -> LocalizationService {
        LocalizationService(settings: store, systemDefaults: defaults)
    }

    // MARK: - 文案解析

    func testChineseLanguageResolvesLocalizedTagline() {
        let service = makeService(store: makeStore(), defaults: makeDefaults())

        service.setLanguage(.simplifiedChinese)

        XCTAssertEqual(service.string("app.tagline"), "macOS 上的轻量文本编辑器")
        XCTAssertEqual(service.string("app.name"), "TXTForMac")
    }

    func testEnglishLanguageResolvesLocalizedTagline() {
        let service = makeService(store: makeStore(), defaults: makeDefaults())

        service.setLanguage(.english)

        XCTAssertEqual(service.string("app.tagline"), "A lightweight text editor for macOS")
    }

    func testUnknownKeyFallsBackToKeyItself() {
        let service = makeService(store: makeStore(), defaults: makeDefaults())

        XCTAssertEqual(service.string("does.not.exist"), "does.not.exist")
    }

    func testFormattedStringSubstitutesArguments() {
        let service = makeService(store: makeStore(), defaults: makeDefaults())

        service.setLanguage(.english)

        XCTAssertEqual(
            service.string("test.statusbar.lineColumn", 3, 12),
            "Line 3, Column 12"
        )
    }

    // MARK: - 持久化

    func testLanguageChangePersistsIntoSettingsStore() {
        let store = makeStore()
        let service = makeService(store: store, defaults: makeDefaults())

        service.setLanguage(.simplifiedChinese)

        XCTAssertEqual(store.settings.interfaceLanguage, .simplifiedChinese)
    }

    func testServiceRestoresLanguageFromPersistedSettings() {
        let store = makeStore()
        store.update { $0.interfaceLanguage = .english }

        let service = makeService(store: store, defaults: makeDefaults())

        XCTAssertEqual(service.language, .english)
        XCTAssertEqual(service.string("app.tagline"), "A lightweight text editor for macOS")
    }

    // MARK: - 系统语言镜像

    /// 断言必须落在套件自身的持久域上：`UserDefaults(suiteName:)` 的读取会回落到
    /// 用户全局域，直接读键会误判「移除覆盖」是否生效。
    func testLanguageChangeMirrorsSystemPreferenceAndClearsOnSystem() throws {
        let defaults = makeDefaults()
        let service = makeService(store: makeStore(), defaults: defaults)

        service.setLanguage(.simplifiedChinese)
        let writtenDomain = try XCTUnwrap(defaults.persistentDomain(forName: suiteName))
        XCTAssertEqual(
            writtenDomain[SettingsSchema.systemLanguageOverrideKey] as? [String],
            ["zh-Hans"]
        )

        service.setLanguage(.system)
        let clearedDomain = defaults.persistentDomain(forName: suiteName) ?? [:]
        XCTAssertNil(clearedDomain[SettingsSchema.systemLanguageOverrideKey])
    }
}

private extension LocalizationServiceTests {
    func makeDefaults() -> UserDefaults {
        suiteName = "txtformac-localization-tests-\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName) ?? .standard
    }
}
