@testable import TXTForMac
import XCTest

/// 守护配置存储的核心契约（ADR-004）：单一来源、损坏回落、迁移容忍、原子写盘。
@MainActor
final class SettingsStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("txtformac-settings-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private var configFileURL: URL {
        tempDirectory.appendingPathComponent(SettingsSchema.fileName)
    }

    // MARK: - 默认值

    func testMissingFileFallsBackToDefaultsAndCreatesFile() {
        let store = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())

        XCTAssertEqual(store.settings, AppSettings.default)
        XCTAssertTrue(FileManager.default.fileExists(atPath: configFileURL.path))
    }

    func testDefaultsKeepLargeFileThresholdsCoherent() {
        XCTAssertLessThan(
            AppSettings.default.largeFileWarningThresholdBytes,
            AppSettings.default.readOnlyThresholdBytes
        )
        XCTAssertGreaterThan(AppSettings.default.largeFileWarningThresholdBytes, 0)
    }

    // MARK: - 损坏回落

    func testCorruptFileFallsBackToDefaultsAndIsBackedUp() throws {
        let corruptContent = #"{"schemaVersion":1,"editorFontSize": broken"#
        try corruptContent.data(using: .utf8)?.write(to: configFileURL)

        let store = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())

        XCTAssertEqual(store.settings, AppSettings.default)

        let backupURLs = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(SettingsSchema.corruptBackupPrefix) }
        XCTAssertEqual(backupURLs.count, 1)
        XCTAssertEqual(try String(contentsOf: backupURLs[0], encoding: .utf8), corruptContent)
    }

    // MARK: - 迁移容忍

    func testUnknownFieldsAreIgnoredAndMissingFieldsUseDefaults() throws {
        let partialJSON = #"{"schemaVersion":1,"editorFontSize":15}"#
        try partialJSON.data(using: .utf8)?.write(to: configFileURL)

        let store = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())

        XCTAssertEqual(store.settings.editorFontSize, 15)
        XCTAssertEqual(store.settings.interfaceLanguage, AppSettings.default.interfaceLanguage)
        XCTAssertEqual(store.settings.readOnlyThresholdBytes, AppSettings.default.readOnlyThresholdBytes)
    }

    func testOlderSchemaVersionStillLoads() throws {
        let olderJSON = #"{"schemaVersion":0}"#
        try olderJSON.data(using: .utf8)?.write(to: configFileURL)

        let store = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())

        XCTAssertEqual(store.settings, AppSettings.default)
    }

    // MARK: - 写盘

    func testUpdatePersistsAndRoundTripsAcrossInstances() {
        let store = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())

        store.update { settings in
            settings.editorFontSize = 18
            settings.theme = .dark
            settings.recentFilesLimit = 5
        }

        XCTAssertEqual(store.settings.editorFontSize, 18)

        let reloaded = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())
        XCTAssertEqual(reloaded.settings.editorFontSize, 18)
        XCTAssertEqual(reloaded.settings.theme, .dark)
        XCTAssertEqual(reloaded.settings.recentFilesLimit, 5)
    }

    func testRapidUpdatesAlwaysLeaveAValidFile() throws {
        let store = SettingsStore(fileURL: configFileURL, broadcaster: SpyBroadcaster())

        for size in 10 ... 30 {
            store.update { $0.editorFontSize = Double(size) }
            let data = try Data(contentsOf: configFileURL)
            let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
            XCTAssertEqual(decoded.editorFontSize, Double(size))
        }
    }

    // MARK: - 变更广播

    func testUpdateNotifiesBroadcasterOncePerChange() {
        let broadcaster = SpyBroadcaster()
        let store = SettingsStore(fileURL: configFileURL, broadcaster: broadcaster)

        store.update { $0.editorFontSize = 16 }
        store.update { $0.editorFontSize = 17 }

        XCTAssertEqual(broadcaster.changeCount, 2)
    }

    func testLoadingWithoutChangeDoesNotNotify() {
        let broadcaster = SpyBroadcaster()
        _ = SettingsStore(fileURL: configFileURL, broadcaster: broadcaster)

        XCTAssertEqual(broadcaster.changeCount, 0)
    }
}

/// 测试用广播器，记录调用次数。
private final class SpyBroadcaster: SettingsChangeBroadcaster, @unchecked Sendable {
    private(set) var changeCount = 0

    func postChange() {
        changeCount += 1
    }
}
