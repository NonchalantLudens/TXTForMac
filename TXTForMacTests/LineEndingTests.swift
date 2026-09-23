@testable import TXTForMac
import XCTest

final class LineEndingTests: XCTestCase {
    func testSequencesAreCorrect() {
        XCTAssertEqual(LineEnding.lf.sequence, "\n")
        XCTAssertEqual(LineEnding.crlf.sequence, "\r\n")
        XCTAssertEqual(LineEnding.cr.sequence, "\r")
    }

    func testDetectsPureEndings() {
        XCTAssertEqual(LineEnding.detect(in: "a\nb\nc"), .lf)
        XCTAssertEqual(LineEnding.detect(in: "a\r\nb\r\nc"), .crlf)
        XCTAssertEqual(LineEnding.detect(in: "a\rb\rc"), .cr)
        XCTAssertNil(LineEnding.detect(in: "no line endings"))
        XCTAssertNil(LineEnding.detect(in: ""))
    }

    func testDetectsDominantEndingInMixedText() {
        let mixed = "a\r\nb\nc\rd\r\ne"
        XCTAssertEqual(LineEnding.detect(in: mixed), .crlf)
    }

    func testCountingDoesNotDoubleCount() {
        let counts = LineEnding.counts(in: "a\r\nb\nc\rd")
        XCTAssertEqual(counts[.crlf], 1)
        XCTAssertEqual(counts[.lf], 1)
        XCTAssertEqual(counts[.cr], 1)
    }

    func testConversionNormalizesMixedInput() {
        let mixed = "a\r\nb\rc\nd"
        XCTAssertEqual(LineEnding.lf.applying(to: mixed), "a\nb\nc\nd")
        XCTAssertEqual(LineEnding.crlf.applying(to: mixed), "a\r\nb\r\nc\r\nd")
        XCTAssertEqual(LineEnding.cr.applying(to: mixed), "a\rb\rc\rd")
    }

    func testCodableRoundTripKeepsHistoricalSpelling() throws {
        let data = try JSONEncoder().encode(LineEnding.crlf)
        XCTAssertEqual(String(data: data, encoding: .utf8), #""crlf""#)
        XCTAssertEqual(try JSONDecoder().decode(LineEnding.self, from: data), .crlf)
    }
}
