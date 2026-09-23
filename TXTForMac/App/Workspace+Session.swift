import Foundation

// MARK: - 自动保存与会话恢复（T-030/T-031）

extension Workspace {
    /// 启动自动保存定时器（幂等）。
    func startAutosave() {
        guard autosaveTimer == nil, settings.settings.autoSaveEnabled else { return }
        let interval = TimeInterval(max(settings.settings.autoSaveIntervalSeconds, 1))
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveDirtyDocuments()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autosaveTimer = timer
    }

    func stopAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = nil
    }

    /// 把已落盘的脏文档写回（未命名文档不入盘，留在会话里）。
    func saveDirtyDocuments() {
        for document in store.documents where document.isDirty {
            guard let url = document.fileURL else { continue }
            _ = save(document: document, to: url)
        }
        persistSession()
    }

    // MARK: 会话快照

    /// 当前窗口的会话快照：磁盘文件记路径，未命名/未保存内容记正文。
    func snapshotSession() -> SessionSnapshot {
        let tabs = store.documents.map { document in
            SessionSnapshot.Tab(
                path: document.fileURL?.path,
                unsavedText: document.isDirty || document.fileURL == nil ? document.text : nil,
                encoding: document.encoding,
                lineEnding: document.lineEnding,
                hasBOM: document.hasBOM
            )
        }
        return SessionSnapshot(tabs: tabs, savedAt: Date.now)
    }

    /// 按设置持久化或清除会话。
    func persistSession() {
        if settings.settings.saveSessionOnClose, !store.isEmpty {
            SessionStore.save(snapshotSession())
        } else {
            SessionStore.clear()
        }
    }

    /// 恢复会话到本窗口（仅应用启动后的第一个窗口调用一次）。
    func restoreSessionIfNeeded() {
        guard !SessionRestoreState.hasRestored else { return }
        SessionRestoreState.hasRestored = true
        switch settings.settings.launchBehavior {
        case .blankDocument:
            return
        case .recentFiles:
            if let recent = SettingsStore.shared.settings.recentFiles.first {
                open(url: URL(fileURLWithPath: recent))
            }
            return
        case .restoreLastSession:
            break
        }

        guard let snapshot = SessionStore.load(), !snapshot.tabs.isEmpty else { return }
        for tab in snapshot.tabs {
            if let path = tab.path, FileManager.default.fileExists(atPath: path) {
                open(url: URL(fileURLWithPath: path))
                continue
            }
            guard let text = tab.unsavedText else { continue }
            let document = Document(settings: settings.settings)
            document.replaceWholeText(with: text, undoably: false)
            document.restoreState(encoding: tab.encoding, lineEnding: tab.lineEnding, hasBOM: tab.hasBOM)
            store.open(document)
        }
        refreshStatusMetrics()
    }

    /// 关闭单个标签（T-027/T-031）：脏文档先确认，成功后落会话。
    func closeTab(at index: Int) {
        guard let document = store.documents[safe: index] else { return }
        if document.isDirty, !confirmDiscardChanges(document: document) {
            return
        }
        store.close(at: index)
        if store.isEmpty {
            SessionStore.clear()
        } else {
            persistSession()
        }
        refreshStatusMetrics()
        refreshWindowEditedFlag()
    }

    func closeCurrentTab() {
        guard let index = store.currentIndex else {
            closeCurrentWindow()
            return
        }
        closeTab(at: index)
    }
}

/// 会话恢复只发生一次（多窗口时其余窗口保持空白）。
@MainActor
enum SessionRestoreState {
    static var hasRestored = false
}

extension Array {
    /// 安全下标。
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
