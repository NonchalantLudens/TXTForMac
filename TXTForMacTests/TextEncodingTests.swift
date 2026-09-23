@testable import TXTForMac
import XCTest

final class TextEncodingTests: XCTestCase {
    func testStringEncodingMapping() {
        XCTAssertEqual(TextEncoding.utf8.stringEncoding, .utf8)
        XCTAssertEqual(TextEncoding.utf16LittleEndian.stringEncoding, .utf16LittleEndian)
        XCTAssertEqual(TextEncoding.utf16BigEndian.stringEncoding, .utf16BigEndian)
        XCTAssertEqual(TextEncoding.big5.stringEncoding, TextEncoding.big5StringEncoding)
        XCTAssertEqual(TextEncoding.shiftJIS.stringEncoding, .shiftJIS)
        XCTAssertEqual(TextEncoding.latin1.stringEncoding, .isoLatin1)
        XCTAssertEqual(TextEncoding.ascii.stringEncoding, .ascii)
        XCTAssertEqual(TextEncoding.gb18030.stringEncoding.rawValue, TextEncoding.gb18030StringEncoding.rawValue)
    }

    func testBOMWritingStrategies() {
        XCTAssertTrue(TextEncoding.utf8BOM.writesBOM)
        XCTAssertTrue(TextEncoding.utf16LittleEndian.writesBOM)
        XCTAssertFalse(TextEncoding.utf8.writesBOM)
        XCTAssertNil(TextEncoding.gb18030.bom)
    }

    func testEncodeWritesBOMOnlyForBOMEncodings() throws {
        let payload = "中文"
        let utf8 = TextEncoding.utf8.encode(payload)
        let utf8BOM = TextEncoding.utf8BOM.encode(payload)
        XCTAssertEqual(try Array(XCTUnwrap(utf8?.prefix(3))), Array("中".utf8.prefix(3)))
        XCTAssertEqual(try Array(XCTUnwrap(utf8BOM?.prefix(3))), [0xEF, 0xBB, 0xBF])
    }

    func testDecodingRejectsInvalidUTF8() {
        let invalid = Data([0x61, 0xC3, 0x28]) // “a” + 截断的多字节序列
        XCTAssertNil(TextEncoding.utf8.decode(invalid))
    }

    func testStrippingBOMRecognizesAllBOMEncodings() {
        let utf8BOM = Data([0xEF, 0xBB, 0xBF]) + Data("x".utf8)
        let (payload, bom) = TextEncoding.strippingBOM(from: utf8BOM)
        XCTAssertEqual(bom, [0xEF, 0xBB, 0xBF])
        XCTAssertEqual(payload, Data("x".utf8))

        let plain = Data("x".utf8)
        let (plainPayload, plainBOM) = TextEncoding.strippingBOM(from: plain)
        XCTAssertNil(plainBOM)
        XCTAssertEqual(plainPayload, plain)
    }

    func testASCIIEncodingRefusesNonASCIIText() {
        XCTAssertNil(TextEncoding.ascii.encode("中文"))
    }
}
