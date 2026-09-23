@testable import TXTForMac
import XCTest

final class FileNamingTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("txtformac-naming-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testAutoNumberSkipsExistingNames() throws {
        try Data().write(to: tempDirectory.appendingPathComponent("新建文本文件.txt"))
        try Data().write(to: tempDirectory.appendingPathComponent("新建文本文件 2.txt"))

        let name = FileNaming.availableFileName(
            base: "新建文本文件", ext: "txt",
            in: tempDirectory, policy: .autoNumber
        )

        XCTAssertEqual(name, "新建文本文件 3.txt")
    }

    func testDuplicateCopyAppendsCopyMarker() throws {
        try Data().write(to: tempDirectory.appendingPathComponent("notes.md"))
        try Data().write(to: tempDirectory.appendingPathComponent("notes 副本.md"))

        let name = FileNaming.availableFileName(
            base: "notes", ext: "md",
            in: tempDirectory, policy: .duplicateCopy
        )

        XCTAssertEqual(name, "notes 副本 2.md")
    }

    func testExtensionNormalizesLeadingDot() {
        let name = FileNaming.availableFileName(
            base: "a", ext: ".log", in: tempDirectory, policy: .autoNumber
        )
        XCTAssertEqual(name, "a.log")
    }

    func testEmptyBaseFallsBackToUntitled() {
        let names = FileNaming.candidateNames(base: "", ext: "txt", policy: .autoNumber)
        XCTAssertEqual(names.first, "Untitled.txt")
    }

    func testCandidatesAreDeterministic() {
        let names = FileNaming.candidateNames(base: "n", ext: "txt", policy: .autoNumber)
        XCTAssertEqual(names.prefix(3), ["n.txt", "n 2.txt", "n 3.txt"])
    }
}
