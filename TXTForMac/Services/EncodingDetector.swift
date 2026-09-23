import Foundation

/// 编码自动判定（T-007）：BOM → UTF-8 严格校验 → 多候选打分。
///
/// 判定链与打分设计见 SPEC US-001 / T-007：
/// 1. BOM 优先（UTF-8 BOM、UTF-16 LE/BE）
/// 2. 无 BOM 时 UTF-8 严格校验通过即 UTF-8
/// 3. 其余候选（GB18030/Big5/Shift-JIS/Latin-1）按「解码质量 + 各自高频字符占比」打分，
///    全部失败时回落 GB18030（中文环境默认，且 GB18030 为近全映射编码，永不解码失败）
enum EncodingDetector {
    /// 拉丁字母与扩展（Latin-1 信号）
    private static func isCommonLatin(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x41 ... 0x5A, 0x61 ... 0x7A, 0xC0 ... 0xFF, 0x100 ... 0x17F: true
        default: false
        }
    }

    private static func characterSet(for encoding: TextEncoding) -> (Unicode.Scalar) -> Bool {
        switch encoding {
        case .gb18030:
            { EncodingCorpus.commonSimplified.contains($0) }
        case .big5:
            { EncodingCorpus.commonTraditional.contains($0) }
        case .shiftJIS:
            { EncodingCorpus.commonJapanese.contains($0) }
        case .latin1, .ascii:
            isCommonLatin
        case .utf8, .utf8BOM, .utf16LittleEndian, .utf16BigEndian:
            { _ in false }
        }
    }

    /// BOM 判定
    static func detectByBOM(_ data: Data) -> TextEncoding? {
        for encoding in TextEncoding.allCases where encoding.writesBOM {
            if let bom = encoding.bom, data.starts(with: bom) {
                return encoding
            }
        }
        return nil
    }

    /// 主判定入口
    static func detect(in data: Data) -> TextEncoding {
        if let byBOM = detectByBOM(data) {
            return byBOM
        }
        if TextEncoding.utf8.decode(data) != nil {
            return .utf8
        }

        let candidates: [TextEncoding] = [.gb18030, .big5, .shiftJIS, .latin1]
        var best = TextEncoding.gb18030
        var bestScore = -Double.greatestFiniteMagnitude
        for candidate in candidates {
            guard let text = candidate.decode(data) else { continue }
            let score = score(text: text, candidate: candidate)
            if score > bestScore {
                bestScore = score
                best = candidate
            }
        }
        return best
    }

    /// 单候选打分：解码质量 + 高频字符占比加权。
    static func score(text: String, candidate: TextEncoding) -> Double {
        var plausible = 0.0
        var suspicious = 0.0
        var total = 0.0
        var common = 0.0
        let isCommon = characterSet(for: candidate)

        for scalar in text.unicodeScalars {
            total += 1
            if isCommon(scalar) {
                common += 1
            }
            switch scalar.value {
            case 0x0A, 0x0D, 0x09:
                plausible += 1
            case 0x20 ... 0x7E:
                plausible += 1
            case 0x4E00 ... 0x9FFF, 0x3400 ... 0x4DBF:
                plausible += 2
            case 0x3040 ... 0x30FF, 0x31F0 ... 0x31FF:
                plausible += 2
            case 0x3000 ... 0x303F, 0xFF00 ... 0xFFEF:
                plausible += 1.5
            case 0xE000 ... 0xF8FF:
                suspicious += 3
            case 0x00 ... 0x08, 0x0B, 0x0C, 0x0E ... 0x1F, 0x7F, 0x80 ... 0x9F:
                suspicious += 2
            default:
                break
            }
        }
        guard total > 0 else { return 0 }
        return (plausible - suspicious) / total + (common / total) * 3
    }
}
