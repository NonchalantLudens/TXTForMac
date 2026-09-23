@testable import TXTForMac
import XCTest

/// 语料集判定（US-001 验收 2 / T-007 验收）：各编码语料必须判定正确。
final class EncodingDetectorTests: XCTestCase {
    private func data(_ text: String, encoding: TextEncoding) throws -> Data {
        try XCTUnwrap(encoding.encode(text), "语料无法按 \(encoding.rawValue) 编码")
    }

    func testDetectsUTF8WithoutBOM() throws {
        XCTAssertEqual(try EncodingDetector.detect(in: data("中文检测 plain", encoding: .utf8)), .utf8)
    }

    func testDetectsUTF8BOM() throws {
        XCTAssertEqual(
            try EncodingDetector.detect(in: data("中文检测", encoding: .utf8BOM)),
            .utf8BOM
        )
    }

    func testDetectsUTF16ByBOM() throws {
        XCTAssertEqual(
            try EncodingDetector.detect(in: data("中文检测", encoding: .utf16LittleEndian)),
            .utf16LittleEndian
        )
        XCTAssertEqual(
            try EncodingDetector.detect(in: data("中文检测", encoding: .utf16BigEndian)),
            .utf16BigEndian
        )
    }

    func testDetectsSimplifiedChineseAsGB18030() throws {
        let corpus = "中文测试编码自动判定，第二行内容：轻量文本编辑器。"
        XCTAssertEqual(try EncodingDetector.detect(in: data(corpus, encoding: .gb18030)), .gb18030)
    }

    func testDetectsTraditionalChineseAsBig5() throws {
        let corpus = "中文測試編碼自動判定，第二行內容：輕量文字編輯器。"
        XCTAssertEqual(try EncodingDetector.detect(in: data(corpus, encoding: .big5)), .big5)
    }

    func testDetectsJapaneseAsShiftJIS() throws {
        let corpus = "日本語のテキストです。これは軽量テキストエディタのテストです。"
        XCTAssertEqual(try EncodingDetector.detect(in: data(corpus, encoding: .shiftJIS)), .shiftJIS)
    }

    func testDetectsLatin1Text() throws {
        let corpus = "café naïve résumé jalapeño über straße"
        XCTAssertEqual(try EncodingDetector.detect(in: data(corpus, encoding: .latin1)), .latin1)
    }

    func testPlainASCIIIsReportedAsUTF8() throws {
        XCTAssertEqual(try EncodingDetector.detect(in: data("hello world", encoding: .utf8)), .utf8)
    }

    func testEmptyDataFallsBackToUTF8() {
        XCTAssertEqual(EncodingDetector.detect(in: Data()), .utf8)
    }

    func testQualityScorePrefersPrivateUseSuspicion() {
        let garbage = "\u{E000}\u{E001}\u{E002}"
        let clean = "常见汉字字符"
        XCTAssertLessThan(
            EncodingDetector.score(text: garbage, candidate: .gb18030),
            EncodingDetector.score(text: clean, candidate: .gb18030)
        )
    }
}
