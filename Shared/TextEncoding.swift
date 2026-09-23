import CoreFoundation
import Foundation

/// 文本编码模型（T-006）：与 `String.Encoding` 的映射、BOM 策略与编解码。
///
/// 原始值同时是 config.json 中的存储拼写（与 `EncodingIdentifier` 历史值一致），一经发布不可改写。
public enum TextEncoding: String, Codable, CaseIterable, Sendable {
    case utf8 = "utf-8"
    case utf8BOM = "utf-8-bom"
    case utf16LittleEndian = "utf-16le"
    case utf16BigEndian = "utf-16be"
    case gb18030
    case big5
    case shiftJIS = "shift-jis"
    case latin1 = "latin-1"
    case ascii

    /// 状态栏显示用的本地化键
    public var localizationKey: String {
        "encoding.\(rawValue)"
    }

    /// Foundation 没有常量的编码（GB18030/Big5）经 CoreFoundation 转换取得。
    public static func cfEncoding(_ encoding: CFStringEncodings) -> String.Encoding {
        String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(encoding.rawValue)))
    }

    public static let gb18030StringEncoding = cfEncoding(.GB_18030_2000)
    public static let big5StringEncoding = cfEncoding(.big5)

    public var stringEncoding: String.Encoding {
        switch self {
        case .utf8, .utf8BOM: .utf8
        case .utf16LittleEndian: .utf16LittleEndian
        case .utf16BigEndian: .utf16BigEndian
        case .gb18030: Self.gb18030StringEncoding
        case .big5: Self.big5StringEncoding
        case .shiftJIS: .shiftJIS
        case .latin1: .isoLatin1
        case .ascii: .ascii
        }
    }

    /// BOM 字节序列；无 BOM 的编码返回 nil。
    public var bom: [UInt8]? {
        switch self {
        case .utf8, .utf8BOM: [0xEF, 0xBB, 0xBF]
        case .utf16LittleEndian: [0xFF, 0xFE]
        case .utf16BigEndian: [0xFE, 0xFF]
        case .gb18030, .big5, .shiftJIS, .latin1, .ascii: nil
        }
    }

    /// 该编码是否默认写 BOM
    public var writesBOM: Bool {
        switch self {
        case .utf8BOM, .utf16LittleEndian, .utf16BigEndian: true
        case .utf8, .gb18030, .big5, .shiftJIS, .latin1, .ascii: false
        }
    }

    /// 去除首部 BOM（如有）
    public static func strippingBOM(from data: Data) -> (data: Data, bom: [UInt8]?) {
        for encoding in TextEncoding.allCases {
            guard let bom = encoding.bom, data.starts(with: bom) else { continue }
            return (data.dropFirst(bom.count), bom)
        }
        return (data, nil)
    }

    /// 按本编码编码文本；含 BOM 的编码自动写 BOM。无法表示的字符返回 nil（严格不丢字）。
    public func encode(_ text: String) -> Data? {
        guard let payload = text.data(using: stringEncoding) else { return nil }
        guard writesBOM, let bom else { return payload }
        var output = Data(bom)
        output.append(payload)
        return output
    }

    /// 严格解码；失败返回 nil（由调用方决定报错或换编码）。
    public func decode(_ data: Data) -> String? {
        String(data: data, encoding: stringEncoding)
    }
}
