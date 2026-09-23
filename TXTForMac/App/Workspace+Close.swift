import AppKit

// MARK: - 关闭与未保存确认（US-006）

// MARK: - 关闭与未保存确认（US-006）

extension Workspace: NSWindowDelegate {
    /// ⌘W 语义（US-005）：多标签时先关当前标签，最后一个标签才关窗口。
    func windowShouldClose(_: NSWindow) -> Bool {
        if store.documents.count > 1 {
            closeCurrentTab()
            return false
        }
        let dirtyDocuments = store.documents.filter(\.isDirty)
        guard !dirtyDocuments.isEmpty else { return true }
        return confirmDiscardChanges(documents: dirtyDocuments)
    }

    func windowWillClose(_: Notification) {
        stopAutosave()
        persistSession()
        if let window {
            WorkspaceRegistry.shared.unregister(window: window)
        }
        window = nil
        boundWindowID = nil
    }

    private func confirmDiscardChanges(documents: [Document]) -> Bool {
        for document in documents where !confirmOne(document: document) {
            return false
        }
        return true
    }

    func confirmDiscardChanges(document: Document) -> Bool {
        confirmOne(document: document)
    }

    private func confirmOne(document: Document) -> Bool {
        let alert = NSAlert()
        alert.messageText = String(
            format: LocalizationSnapshot.string("alert.unsaved.title"),
            document.displayName
        )
        alert.informativeText = LocalizationSnapshot.string("alert.unsaved.detail")
        alert.addButton(withTitle: LocalizationSnapshot.string("alert.unsaved.save"))
        alert.addButton(withTitle: LocalizationSnapshot.string("alert.unsaved.discard"))
        alert.addButton(withTitle: LocalizationSnapshot.string("alert.unsaved.cancel"))
        alert.alertStyle = .warning
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            guard let url = document.fileURL else {
                store.select(document)
                return saveAs()
            }
            return save(document: document, to: url)
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }
}
