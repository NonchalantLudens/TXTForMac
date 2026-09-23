import SwiftUI
import UniformTypeIdentifiers

/// 标签栏（T-027/T-028）：选择、关闭、脏标记与拖拽重排。
struct TabBarView: View {
    let store: DocumentStore
    let onSelect: (Int) -> Void
    let onClose: (Int) -> Void

    @State private var draggingID: Document.ID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(store.documents.enumerated()), id: \.element.id) { index, document in
                    tabItem(for: document, index: index)
                }
            }
            .padding(.horizontal, UIConstants.spacingCompact)
        }
        .frame(height: 30)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func tabItem(for document: Document, index: Int) -> some View {
        let isSelected = store.currentIndex == index
        return HStack(spacing: UIConstants.spacingCompact) {
            Text(document.displayName)
                .font(.callout)
                .lineLimit(1)
                .frame(maxWidth: 180)
                .truncationMode(.middle)
            if document.isDirty {
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
            }
            Button {
                onClose(index)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            .opacity(isSelected || document.isDirty ? 1 : 0.4)
        }
        .padding(.horizontal, UIConstants.spacingStandard)
        .frame(height: 26)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadiusControl)
                .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(index)
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onDrag {
            draggingID = document.id
            return NSItemProvider(object: "txtformac.tab.\(document.id.uuidString)" as NSString)
        }
        .onDrop(
            of: [UTType.plainText],
            delegate: TabDropDelegate(
                store: store,
                targetIndex: index,
                draggingID: $draggingID
            )
        )
    }
}

/// 拖拽重排的落点判定（T-028）。
struct TabDropDelegate: DropDelegate {
    let store: DocumentStore
    let targetIndex: Int
    @Binding var draggingID: Document.ID?

    func dropEntered(info _: DropInfo) {
        guard let draggingID,
              let source = store.documents.firstIndex(where: { $0.id == draggingID }),
              source != targetIndex else { return }
        store.move(from: source, to: targetIndex)
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info _: DropInfo) -> Bool {
        draggingID = nil
        return true
    }

    func validateDrop(info _: DropInfo) -> Bool {
        draggingID != nil
    }
}
