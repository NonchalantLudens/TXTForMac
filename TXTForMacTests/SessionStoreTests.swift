@testable import TXTForMac
import XCTest

final class SessionStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("txtformac-session-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private var sessionURL: URL {
        tempDirectory.appendingPathComponent(SessionStore.fileName)
    }

    func testSaveAndLoadRoundTrip() {
        let snapshot = SessionSnapshot(tabs: [
            .init(
                path: "/tmp/a.txt",
                unsavedText: nil,
                encoding: .utf8,
                lineEnding: .lf,
                hasBOM: false
            ),
            .init(
                path: nil,
                unsavedText: "未保存的内容",
                encoding: .gb18030,
                lineEnding: .crlf,
                hasBOM: false
            ),
        ], savedAt: Date.now)

        SessionStore.save(snapshot, to: sessionURL)

        let loaded = SessionStore.load(from: sessionURL)
        XCTAssertEqual(loaded?.tabs, snapshot.tabs)
    }

    func testCorruptSessionLoadsAsNil() throws {
        try Data("not json {{{".utf8).write(to: sessionURL)
        XCTAssertNil(SessionStore.load(from: sessionURL))
    }

    func testMissingSessionLoadsAsNil() {
        XCTAssertNil(SessionStore.load(from: sessionURL))
    }

    func testClearRemovesSessionFile() {
        SessionStore.save(SessionSnapshot(tabs: []), to: sessionURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sessionURL.path))

        SessionStore.clear(at: sessionURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sessionURL.path))
    }
}
