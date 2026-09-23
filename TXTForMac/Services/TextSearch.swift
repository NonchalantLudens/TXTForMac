import Foundation

/// 纯文本/正则查找核心（T-017/T-018）。与 UI 解耦，全部可单测。
enum TextSearch {
    struct Options: Equatable, Sendable {
        var caseSensitive = false
        var wholeWord = false
        var isRegex = false
    }

    /// 查找错误的统一形态（正则非法、模板非法等），由调用方映射为友好文案。
    enum SearchError: Error, Equatable {
        case invalidRegex(String)
        case invalidTemplate(String)
        case emptyQuery
    }

    /// 全部匹配区间（UTF-16，与 NSTextView 选区语义一致，按出现顺序）。
    static func matches(of query: String, in text: String, options: Options) throws -> [NSRange] {
        guard !query.isEmpty else { throw SearchError.emptyQuery }
        let nsText = text as NSString
        if options.isRegex {
            let regex = try makeRegex(pattern: query, options: options)
            let full = NSRange(location: 0, length: nsText.length)
            var ranges: [NSRange] = []
            regex.enumerateMatches(in: text, range: full) { match, _, _ in
                if let range = match?.range, range.length > 0 {
                    ranges.append(range)
                }
            }
            return ranges
        }

        var ranges: [NSRange] = []
        let compare: String.CompareOptions = options.caseSensitive ? [] : [.caseInsensitive]
        var location = 0
        while location <= nsText.length {
            let remaining = NSRange(location: location, length: nsText.length - location)
            let found = nsText.range(of: query, options: compare, range: remaining)
            guard found.location != NSNotFound else { break }
            if options.wholeWord, !isWholeWordMatch(query: query, at: found, in: nsText) {
                location = found.location + 1
                continue
            }
            ranges.append(found)
            location = found.location + max(found.length, 1)
        }
        return ranges
    }

    /// 对单个匹配串执行替换（正则时支持 $1 捕获组引用）。
    static func replacing(_ match: String, query: String, template: String, options: Options) throws -> String {
        guard options.isRegex else { return template }
        let regex = try makeRegex(pattern: query, options: options)
        do {
            return try regex.stringByReplacingMatches(
                in: match,
                range: NSRange(location: 0, length: (match as NSString).length),
                withTemplate: template
            )
        } catch {
            throw SearchError.invalidTemplate(template)
        }
    }

    private static func makeRegex(pattern: String, options: Options) throws -> NSRegularExpression {
        do {
            var regexOptions: NSRegularExpression.Options = [.useUnicodeWordBoundaries]
            if !options.caseSensitive {
                regexOptions.insert(.caseInsensitive)
            }
            return try NSRegularExpression(pattern: pattern, options: regexOptions)
        } catch {
            throw SearchError.invalidRegex(pattern)
        }
    }

    private static func isWholeWordMatch(query _: String, at range: NSRange, in nsText: NSString) -> Bool {
        let beforeIsBoundary = range.location == 0 || !isWordCharacter(
            nsText.substring(with: NSRange(location: range.location - 1, length: 1))
        )
        let afterIndex = range.location + range.length
        let afterIsBoundary = afterIndex >= nsText.length || !isWordCharacter(
            nsText.substring(with: NSRange(location: afterIndex, length: 1))
        )
        return beforeIsBoundary && afterIsBoundary
    }

    private static let wordCharacters = CharacterSet.alphanumerics

    private static func isWordCharacter(_ character: String) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        return wordCharacters.contains(scalar)
    }
}
