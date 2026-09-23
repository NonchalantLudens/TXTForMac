import Foundation

/// Finder 新建文件的命名与冲突策略（T-040，主 App 与扩展共用）。
public enum FileNaming {
    /// 按策略生成候选文件名序列（依次尝试直到不冲突）。
    ///
    /// - autoNumber：`base.ext`、`base 2.ext`、`base 3.ext`…
    /// - duplicateCopy：`base.ext`、`base 副本.ext`、`base 副本 2.ext`…
    /// - ask：扩展端无法弹 UI，按 autoNumber 生成，主 App 打开后由用户改名（见设置页说明）
    public static func candidateNames(base: String, ext: String, policy: NamingConflictPolicy) -> [String] {
        let suffix = normalizedExtension(ext)
        let stem = base.isEmpty ? "Untitled" : base
        switch policy {
        case .autoNumber, .ask:
            var names = [withExtension(stem, suffix)]
            var index = 2
            while names.count < 1000 {
                names.append(withExtension("\(stem) \(index)", suffix))
                index += 1
            }
            return names
        case .duplicateCopy:
            var names = [withExtension(stem, suffix)]
            var index = 1
            while names.count < 1000 {
                let copyStem = index == 1 ? "\(stem) 副本" : "\(stem) 副本 \(index)"
                names.append(withExtension(copyStem, suffix))
                index += 1
            }
            return names
        }
    }

    /// 返回目录中第一个不冲突的文件名；目录不存在时直接返回首个候选。
    public static func availableFileName(
        base: String,
        ext: String,
        in directory: URL,
        policy: NamingConflictPolicy,
        fileManager: FileManager = .default
    ) -> String {
        for name in candidateNames(base: base, ext: ext, policy: policy)
            where !fileManager.fileExists(atPath: directory.appendingPathComponent(name).path)
        {
            return name
        }
        return withExtension("\(base)-\(UUID().uuidString.prefix(6))", normalizedExtension(ext))
    }

    private static func normalizedExtension(_ ext: String) -> String {
        let trimmed = ext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "txt" }
        return trimmed.hasPrefix(".") ? String(trimmed.dropFirst()) : trimmed
    }

    private static func withExtension(_ stem: String, _ ext: String) -> String {
        ext.isEmpty ? stem : "\(stem).\(ext)"
    }
}
