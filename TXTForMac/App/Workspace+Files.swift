import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件打开与保存（T-015）

extension Workspace {
    func openFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.plainText, .utf8PlainText, .text]
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            open(url: url)
        }
    }

    func open(url: URL) {
        noteRecentFile(at: url)
        do {
            let loaded = try FileIOService.read(
                at: url,
                warningThreshold: settings.settings.largeFileWarningThresholdBytes,
                readOnlyThreshold: settings.settings.readOnlyThresholdBytes
            )
            store.open(Document(loaded: loaded, url: url))
            if loaded.policy == .warning {
                banner = .largeFileWarning(byteCount: loaded.byteCount)
            }
            refreshStatusMetrics()
        } catch {
            presentError(error)
        }
    }

    @discardableResult
    func saveCurrent() -> Bool {
        guard let document = store.currentDocument else { return false }
        guard let url = document.fileURL else { return saveAs() }
        return save(document: document, to: url)
    }

    @discardableResult
    func saveAs() -> Bool {
        guard let document = store.currentDocument else { return false }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = document.displayName
        panel.allowedContentTypes = [.plainText]
        let options = SaveOptions(
            encoding: document.encoding,
            lineEnding: document.lineEnding,
            writeBOM: document.hasBOM
        )
        panel.accessoryView = SaveOptionsController(options: options).view
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        return save(document: document, to: url, options: options)
    }

    func save(
        document: Document,
        to url: URL,
        options: SaveOptions? = nil
    ) -> Bool {
        do {
            let encoding = options?.encoding ?? document.encoding
            let lineEnding = options?.lineEnding ?? document.lineEnding
            let writeBOM = options?.writeBOM ?? document.hasBOM
            try FileIOService.write(
                document.text,
                to: url,
                encoding: encoding,
                lineEnding: lineEnding,
                writeBOM: writeBOM,
                backupEnabled: settings.settings.createBackupFile
            )
            document.markSaved(
                to: url,
                encoding: encoding,
                lineEnding: lineEnding,
                hasBOM: writeBOM || encoding.writesBOM
            )
            refreshWindowEditedFlag()
            return true
        } catch {
            presentError(error)
            return false
        }
    }

    /// 「重新打开并指定编码」（T-015）：脏文档先确认，避免误丢内容。
    func reopenDocument(with encoding: TextEncoding) {
        guard let document = store.currentDocument, let url = document.fileURL else { return }
        if document.isDirty, !confirmDiscardChanges(document: document) {
            return
        }
        do {
            let loaded = try FileIOService.read(
                at: url,
                forcing: encoding,
                warningThreshold: settings.settings.largeFileWarningThresholdBytes,
                readOnlyThreshold: settings.settings.readOnlyThresholdBytes
            )
            document.replaceWholeText(with: loaded.text, undoably: false)
            document.markSaved(
                to: url,
                encoding: loaded.encoding,
                lineEnding: loaded.lineEnding,
                hasBOM: loaded.hasBOM
            )
            refreshStatusMetrics()
        } catch {
            presentError(error)
        }
    }
}
