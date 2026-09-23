@testable import TXTForMac
import XCTest

final class TextSearchTests: XCTestCase {
    private let text = "Alfa beta alfa\ngamma beta"

    func testFindsAllMatchesCaseInsensitiveByDefault() throws {
        let ranges = try TextSearch.matches(of: "alfa", in: text, options: .init())
        XCTAssertEqual(ranges.count, 2)
    }

    func testCaseSensitiveOption() throws {
        let ranges = try TextSearch.matches(
            of: "alfa", in: text, options: .init(caseSensitive: true)
        )
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual((text as NSString).substring(with: ranges[0]), "alfa")
    }

    func testWholeWordOptionSkipsSubstrings() throws {
        let ranges = try TextSearch.matches(
            of: "beta", in: "betaX beta beta", options: .init(wholeWord: true)
        )
        XCTAssertEqual(ranges.count, 2)
    }

    func testRegexFindsMatches() throws {
        let ranges = try TextSearch.matches(
            of: #"b\w+"#, in: text, options: .init(isRegex: true)
        )
        XCTAssertEqual(ranges.count, 2)
    }

    func testInvalidRegexThrows() {
        XCTAssertThrowsError(
            try TextSearch.matches(of: "([a", in: text, options: .init(isRegex: true))
        ) { error in
            XCTAssertEqual(error as? TextSearch.SearchError, .invalidRegex("([a"))
        }
    }

    func testEmptyQueryThrows() {
        XCTAssertThrowsError(try TextSearch.matches(of: "", in: text, options: .init()))
    }

    func testLiteralReplacementKeepsTemplateVerbatim() throws {
        let result = try TextSearch.replacing(
            "beta", query: "beta", template: "$0 已换", options: .init()
        )
        XCTAssertEqual(result, "$0 已换")
    }

    func testRegexReplacementSupportsCaptureGroups() throws {
        let result = try TextSearch.replacing(
            "beta-7", query: #"beta-(\d+)"#, template: "编号 $1", options: .init(isRegex: true)
        )
        XCTAssertEqual(result, "编号 7")
    }

    func testUTF16RangesMatchTextViewSelectionSemantics() throws {
        let unicode = "中文 abc 中文"
        let ranges = try TextSearch.matches(of: "中文", in: unicode, options: .init())
        XCTAssertEqual(ranges.count, 2)
        XCTAssertEqual(ranges[0], NSRange(location: 0, length: 2))
        XCTAssertEqual(ranges[1], NSRange(location: 7, length: 2))
    }
}
