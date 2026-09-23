import SwiftUI

/// 状态栏（T-014）：行列 / 字符数 / 选中数 / 编码 / 换行符 / 缩放。
struct StatusBarView: View {
    let workspace: Workspace

    var body: some View {
        HStack(spacing: UIConstants.spacingStandard) {
            Text(workspace.statusLineColumn)
                .monospacedDigit()
            Text(workspace.statusCounts)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer()
            encodingPicker
            lineEndingPicker
            Text(workspace.statusZoom)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, UIConstants.spacingStandard)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var encodingPicker: some View {
        Menu {
            ForEach(TextEncoding.allCases, id: \.self) { encoding in
                Button(LocalizationSnapshot.string(encoding.localizationKey)) {
                    workspace.reopenDocument(with: encoding)
                }
            }
        } label: {
            Text(workspace.statusEncoding)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(workspace.store.currentDocument?.fileURL == nil)
    }

    private var lineEndingPicker: some View {
        Menu {
            ForEach(LineEnding.allCases, id: \.self) { ending in
                Button(LocalizationSnapshot.string(ending.localizationKey)) {
                    workspace.setLineEnding(ending)
                }
            }
        } label: {
            Text(workspace.statusLineEnding)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(workspace.store.currentDocument == nil)
    }
}

/// 状态栏文案（集中格式化，便于测试与本地化）。
extension Workspace {
    var statusLineColumn: String {
        String(
            format: LocalizationSnapshot.string("statusbar.lineColumn"),
            cursorLine, cursorColumn
        )
    }

    var statusCounts: String {
        let counts = String(
            format: LocalizationSnapshot.string("statusbar.characters"),
            characterCount
        )
        guard selectedCount > 0 else { return counts }
        let selected = String(
            format: LocalizationSnapshot.string("statusbar.selected"),
            selectedCount
        )
        return "\(counts) · \(selected)"
    }

    var statusEncoding: String {
        guard let document = store.currentDocument else {
            return LocalizationSnapshot.string("encoding.unknown")
        }
        return LocalizationSnapshot.string(document.encoding.localizationKey)
    }

    var statusLineEnding: String {
        guard let document = store.currentDocument else {
            return LocalizationSnapshot.string("lineEnding.unknown")
        }
        return LocalizationSnapshot.string(document.lineEnding.localizationKey)
    }

    var statusZoom: String {
        String(format: LocalizationSnapshot.string("statusbar.zoom"), zoomPercent)
    }
}
