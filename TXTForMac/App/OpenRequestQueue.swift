import AppKit
import os

/// 打开文件请求的排队器（修复「打开方式」不生效）：
/// AppKit 的 `application(_:open:)` 可能在窗口/工作区就绪前到达，
/// 先入队，等首个工作区可用后按序打开。
@MainActor
final class OpenRequestQueue {
    static let shared = OpenRequestQueue()

    private var pending: [URL] = []
    private let logger = Logger(
        subsystem: "online.nonchalantludens.txtformac",
        category: "OpenRequestQueue"
    )

    func enqueue(_ urls: [URL]) {
        logger.notice("收到打开请求：\(urls.map(\.path), privacy: .public)")
        pending.append(contentsOf: urls)
        drain()
        scheduleRetryIfNeeded()
    }

    /// 冷启动竞态兜底：窗口/工作区未就绪时保留队列，按间隔重试直至打开。
    private func scheduleRetryIfNeeded(attempt: Int = 1) {
        guard !pending.isEmpty, attempt <= 20 else {
            if attempt > 20, !pending.isEmpty {
                logger.error("打开请求重试超限，仍有 \(pending.count) 个待打开文件")
            }
            return
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                guard let self else { return }
                if self.pending.isEmpty {
                    return
                }
                self.drain()
                self.scheduleRetryIfNeeded(attempt: attempt + 1)
            }
        }
    }

    /// 由窗口就绪或 AppKit 打开事件触发；无工作区时保留队列等待。
    func drain(into workspace: Workspace? = nil) {
        guard !pending.isEmpty else { return }
        guard let target = workspace ?? WorkspaceRegistry.shared.active else { return }
        let urls = pending
        pending = []
        for url in urls {
            target.open(url: url)
        }
    }
}
