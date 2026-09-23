@testable import TXTForMac
import XCTest

final class FileIOServiceTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("txtformac-fileio-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func url(_ name: String) -> URL {
        tempDirectory.appendingPathComponent(name)
    }

    // MARK: - 分级

    func testLoadPolicyThresholds() {
        XCTAssertEqual(FileIOService.loadPolicy(byteCount: 10, warningThreshold: 10, readOnlyThreshold: 100), .normal)
        XCTAssertEqual(FileIOService.loadPolicy(byteCount: 50, warningThreshold: 10, readOnlyThreshold: 100), .warning)
        XCTAssertEqual(
            FileIOService.loadPolicy(byteCount: 150, warningThreshold: 10, readOnlyThreshold: 100),
            .readOnly
        )
    }

    // MARK: - 读取

    func testReadDetectsGB18030WithCRLF() throws {
        let text = "第一行\r\n第二行：轻量文本编辑器\r\n"
        let fileURL = url("gbk-crlf.txt")
        try TextEncoding.gb18030.encode(text)?.write(to: fileURL)

        let loaded = try FileIOService.read(at: fileURL)

        XCTAssertEqual(loaded.encoding, .gb18030)
        XCTAssertEqual(loaded.lineEnding, .crlf)
        XCTAssertEqual(loaded.text, text)
        XCTAssertFalse(loaded.hasBOM)
    }

    func testReadStripsUTF8BOMAndReportsIt() throws {
        let fileURL = url("bom.txt")
        try TextEncoding.utf8BOM.encode("中文")?.write(to: fileURL)

        let loaded = try FileIOService.read(at: fileURL)

        XCTAssertTrue(loaded.hasBOM)
        XCTAssertEqual(loaded.encoding, .utf8BOM)
        XCTAssertEqual(loaded.text, "中文")
    }

    func testReadMissingFileThrowsFriendlyError() {
        XCTAssertThrowsError(try FileIOService.read(at: url("missing.txt"))) { error in
            XCTAssertEqual(error as? FileIOServiceError, .fileNotFound)
        }
    }

    func testReadDirectoryThrowsNotRegularFile() {
        let directory = tempDirectory.appendingPathComponent("folder")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        XCTAssertThrowsError(try FileIOService.read(at: directory)) { error in
            XCTAssertEqual(error as? FileIOServiceError, .notRegularFile)
        }
    }

    // MARK: - 写入与往返保真（US-002 验收 1）

    func testRoundTripKeepsEncodingAndLineEndingByteExact() throws {
        let original = "第一行：测试\r\n第二行：保存往返\r\n"
        let fileURL = url("roundtrip.txt")
        try FileIOService.write(original, to: fileURL, encoding: .gb18030, lineEnding: .crlf)

        let first = try FileIOService.read(at: fileURL)
        XCTAssertEqual(first.encoding, .gb18030)
        XCTAssertEqual(first.lineEnding, .crlf)

        let edited = first.text.replacingOccurrences(of: "保存往返", with: "保存後已改")
        try FileIOService.write(edited, to: fileURL, encoding: .gb18030, lineEnding: .crlf)

        let expectedBytes = TextEncoding.gb18030.encode(edited)
        let actualBytes = try Data(contentsOf: fileURL)
        XCTAssertEqual(actualBytes, expectedBytes)
    }

    func testWriteConvertsLineEndingsOnDemand() throws {
        let fileURL = url("convert.txt")
        try FileIOService.write("a\nb\nc", to: fileURL, encoding: .utf8, lineEnding: .crlf)

        let bytes = try Data(contentsOf: fileURL)
        XCTAssertEqual(String(data: bytes, encoding: .utf8), "a\r\nb\r\nc")
    }

    func testWriteCanSwitchEncodingAndBOM() throws {
        let fileURL = url("switch.txt")
        try FileIOService.write("中文内容", to: fileURL, encoding: .utf8, lineEnding: .lf)
        try FileIOService.write("中文内容", to: fileURL, encoding: .utf8, lineEnding: .lf, writeBOM: true)

        let bytes = try Data(contentsOf: fileURL)
        XCTAssertEqual(Array(bytes.prefix(3)), [0xEF, 0xBB, 0xBF])
        let loaded = try FileIOService.read(at: fileURL)
        XCTAssertEqual(loaded.encoding, .utf8BOM)
        XCTAssertEqual(loaded.text, "中文内容")
    }

    func testWriteCreatesBackupWhenEnabled() throws {
        let fileURL = url("backup.txt")
        try FileIOService.write("v1", to: fileURL, encoding: .utf8, lineEnding: .lf)

        try FileIOService.write("v2", to: fileURL, encoding: .utf8, lineEnding: .lf, backupEnabled: true)

        XCTAssertEqual(try String(contentsOf: fileURL.appendingPathExtension("bak"), encoding: .utf8), "v1")
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "v2")
    }

    func testWriteFailsForUnrepresentableContent() {
        XCTAssertThrowsError(
            try FileIOService.write("中文", to: url("ascii.txt"), encoding: .ascii, lineEnding: .lf)
        ) { error in
            XCTAssertEqual(error as? FileIOServiceError, .unencodable(encoding: .ascii))
        }
    }

    func testAtomicWriteCreatesMissingDirectory() throws {
        let nested = tempDirectory.appendingPathComponent("a/b/c/file.txt")
        try FileIOService.write("nested", to: nested, encoding: .utf8, lineEnding: .lf)
        XCTAssertEqual(try String(contentsOf: nested, encoding: .utf8), "nested")
    }
}
