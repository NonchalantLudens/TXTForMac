import Foundation

/// 换行符模型（T-005）：检测、统计与全量转换。
///
/// 原始值同时是 config.json 中的存储拼写，一经发布不可改写。
public enum LineEnding: String, Codable, CaseIterable, Sendable {
    case lf
    case crlf
    case cr

    /// 实际字节序列
    public var sequence: String {
        switch self {
        case .lf: "\n"
        case .crlf: "\r\n"
        case .cr: "\r"
        }
    }

    /// 状态栏显示用的本地化键
    public var localizationKey: String {
        "lineEnding.\(rawValue)"
    }

    /// 统计文本中各换行符出现次数。
    ///
    /// 必须按字节扫描：Swift 的 `\r\n` 是单个字形（Character），
    /// 按字符遍历永远匹配不到独立的 `\r`；且解码得到的字符串可能没有连续 UTF-8 存储。
    public static func counts(in text: String) -> [LineEnding: Int] {
        var lf = 0
        var crlf = 0
        var cr = 0
        var previousWasCR = false
        for byte in text.utf8 {
            if previousWasCR {
                if byte == 0x0A {
                    crlf += 1
                } else {
                    cr += 1
                }
            } else if byte == 0x0A {
                lf += 1
            }
            previousWasCR = byte == 0x0D
        }
        if previousWasCR {
            cr += 1
        }
        return [.lf: lf, .crlf: crlf, .cr: cr]
    }

    /// 检测主导换行符：无换行符返回 nil；混排返回数量最多者（同数按 case 顺序，结果确定）。
    public static func detect(in text: String) -> LineEnding? {
        let counts = counts(in: text)
        var best = LineEnding.lf
        var bestCount = 0
        for candidate in LineEnding.allCases {
            let count = counts[candidate] ?? 0
            if count > bestCount {
                best = candidate
                bestCount = count
            }
        }
        return bestCount > 0 ? best : nil
    }

    /// 全量转换为目标换行符：先归一到 LF 再展开，避免混排叠加。
    public func applying(to text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return normalized.replacingOccurrences(of: "\n", with: sequence)
    }
}
