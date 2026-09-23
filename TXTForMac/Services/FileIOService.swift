import Foundation

/// 读取分级（T-016）：按字节数决定编辑能力。
enum DocumentLoadPolicy: String, Equatable, Sendable {
    case normal
    case warning
    case readOnly
}

/// 一次成功读取的完整事实：文本与它的编码、换行符、BOM、大小与分级。
struct LoadedFile: Equatable, Sendable {
    var text: String
    var encoding: TextEncoding
    var lineEnding: LineEnding
    var hasBOM: Bool
    var byteCount: Int
    var policy: DocumentLoadPolicy
}

/// 文件读写错误（C2：捕获 → 转换 → 友好文案）。
enum FileIOServiceError: LocalizedError, Equatable {
    case fileNotFound
    case notRegularFile
    case undecodable(encoding: TextEncoding)
    case unencodable(encoding: TextEncoding)
    case writeFailed(String)

    var errorDescriptionKey: String {
        switch self {
        case .fileNotFound: "error.fileNotFound"
        case .notRegularFile: "error.notRegularFile"
        case .undecodable: "error.undecodable"
        case .unencodable: "error.unencodable"
        case .writeFailed: "error.writeFailed"
        }
    }

    var errorArguments: [String] {
        switch self {
        case let .undecodable(encoding), let .unencodable(encoding):
            [encoding.rawValue]
        case let .writeFailed(reason):
            [reason]
        default:
            []
        }
    }

    var errorDescription: String? {
        let format = LocalizationSnapshot.string(errorDescriptionKey)
        guard !errorArguments.isEmpty else { return format }
        return String(format: format, arguments: errorArguments)
    }
}

/// 全部文件读写的唯一入口（T-008/T-009，ADR-004 配套约束）。
enum FileIOService {
    /// 按阈值给出读取分级：≤警告阈值全功能；≤只读阈值警告；超过只读。
    static func loadPolicy(
        byteCount: Int,
        warningThreshold: Int,
        readOnlyThreshold: Int
    ) -> DocumentLoadPolicy {
        if byteCount <= warningThreshold {
            return .normal
        }
        if byteCount <= readOnlyThreshold {
            return .warning
        }
        return .readOnly
    }

    /// 读取文本文件：判编码（T-007）→ 严格解码 → 剥 BOM → 探测换行符 → 分级。
    static func read(
        at url: URL,
        warningThreshold: Int = 20 * ByteCount.megabyte,
        readOnlyThreshold: Int = 100 * ByteCount.megabyte
    ) throws -> LoadedFile {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw FileIOServiceError.fileNotFound
        }
        guard !isDirectory.boolValue else { throw FileIOServiceError.notRegularFile }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw FileIOServiceError.writeFailed(error.localizedDescription)
        }

        let (payload, bom) = TextEncoding.strippingBOM(from: data)
        let encoding: TextEncoding = if let bom {
            bomEncoding(bom)
        } else {
            EncodingDetector.detect(in: payload)
        }

        guard let text = encoding.decode(payload) else {
            throw FileIOServiceError.undecodable(encoding: encoding)
        }

        return LoadedFile(
            text: text,
            encoding: encoding,
            lineEnding: LineEnding.detect(in: text) ?? .lf,
            hasBOM: bom != nil,
            byteCount: data.count,
            policy: loadPolicy(
                byteCount: data.count,
                warningThreshold: warningThreshold,
                readOnlyThreshold: readOnlyThreshold
            )
        )
    }

    private static func bomEncoding(_ bom: [UInt8]) -> TextEncoding {
        // 只在「默认写 BOM」的编码里反查，避免与不带 BOM 的同前缀编码（UTF-8）混淆
        TextEncoding.allCases.first { $0.writesBOM && $0.bom == bom } ?? .utf8BOM
    }

    /// 写入文本文件：换行符归一 → 编码 → 原子写 → 可选 `.bak` 备份。
    static func write(
        _ text: String,
        to url: URL,
        encoding: TextEncoding,
        lineEnding: LineEnding,
        writeBOM: Bool = false,
        backupEnabled: Bool = false,
        fileManager: FileManager = .default
    ) throws {
        let converted = lineEnding.applying(to: text)
        var target = encoding
        if writeBOM, target == .utf8 {
            target = .utf8BOM
        } else if !writeBOM, target == .utf8BOM {
            target = .utf8
        }
        guard let data = target.encode(converted) else {
            throw FileIOServiceError.unencodable(encoding: target)
        }

        let directory = url.deletingLastPathComponent()
        do {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            if backupEnabled, fileManager.fileExists(atPath: url.path) {
                let backupURL = url.appendingPathExtension("bak")
                try? fileManager.removeItem(at: backupURL)
                try fileManager.copyItem(at: url, to: backupURL)
            }
            try data.write(to: url, options: [.atomic])
        } catch {
            throw FileIOServiceError.writeFailed(error.localizedDescription)
        }
    }
}
