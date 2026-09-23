import Foundation

/// 一个窗口内全部文档的集合与当前标签（T-010）。
@MainActor
@Observable
final class DocumentStore {
    private(set) var documents: [Document] = []
    private(set) var currentIndex: Int?

    var currentDocument: Document? {
        guard let currentIndex, documents.indices.contains(currentIndex) else { return nil }
        return documents[currentIndex]
    }

    var dirtyCount: Int {
        documents.filter(\.isDirty).count
    }

    var isEmpty: Bool {
        documents.isEmpty
    }

    /// 打开（追加并选中）。
    func open(_ document: Document) {
        if let existing = documents.first(where: { $0.fileURL != nil && $0.fileURL == document.fileURL }) {
            select(existing)
            return
        }
        documents.append(document)
        currentIndex = documents.count - 1
    }

    /// 选中文档；不存在时忽略。
    func select(_ document: Document) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        currentIndex = index
    }

    func select(index: Int) {
        guard documents.indices.contains(index) else { return }
        currentIndex = index
    }

    /// 关闭指定位置的文档，返回被关闭者；当前选中自动指向相邻文档。
    @discardableResult
    func close(at index: Int) -> Document? {
        guard documents.indices.contains(index) else { return nil }
        let removed = documents.remove(at: index)
        if documents.isEmpty {
            currentIndex = nil
        } else if index == currentIndex {
            currentIndex = min(index, documents.count - 1)
        } else if index < (currentIndex ?? 0) {
            currentIndex = (currentIndex ?? 1) - 1
        }
        return removed
    }

    /// 重排（T-028）。
    func move(from source: Int, to destination: Int) {
        guard documents.indices.contains(source),
              destination >= 0, destination < documents.count else { return }
        let current = currentDocument
        let document = documents.remove(at: source)
        documents.insert(document, at: destination)
        currentIndex = current.flatMap { current in documents.firstIndex { $0.id == current.id } }
    }

    /// 把文档迁移到另一个窗口的仓库（T-029）。
    func transfer(_ document: Document, to other: DocumentStore) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        close(at: index)
        other.open(document)
    }
}
