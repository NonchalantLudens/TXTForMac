import Foundation

/// 会话快照（T-031）：标签集合与未保存内容的持久化形态。
struct SessionSnapshot: Codable, Equatable, Sendable {
    struct Tab: Codable, Equatable, Sendable {
        var path: String?
        var unsavedText: String?
        var encoding: TextEncoding
        var lineEnding: LineEnding
        var hasBOM: Bool
    }

    var tabs: [Tab] = []
    var savedAt: Date?

    static func == (lhs: SessionSnapshot, rhs: SessionSnapshot) -> Bool {
        lhs.tabs == rhs.tabs
    }
}

/// 会话持久化的唯一入口：写 `session.json`，损坏即丢弃（US-006 验收 4）。
enum SessionStore {
    static let fileName = "session.json"

    static func fileURL(in directory: URL? = nil) -> URL {
        let base = directory ?? (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(SettingsSchema.directoryName, isDirectory: true))
        guard let base else {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        }
        return base.appendingPathComponent(fileName)
    }

    /// 快照损坏时返回 nil（调用方降级为空会话），不抛错不阻塞启动。
    static func load(from url: URL = SessionStore.fileURL()) -> SessionSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SessionSnapshot.self, from: data)
    }

    static func save(_ snapshot: SessionSnapshot, to url: URL = SessionStore.fileURL()) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: [.atomic])
    }

    static func clear(at url: URL = SessionStore.fileURL()) {
        try? FileManager.default.removeItem(at: url)
    }
}
