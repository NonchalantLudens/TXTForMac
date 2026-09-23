import SwiftUI

/// 主窗口根视图（T-012）：编辑器外壳 + 提示条 + 状态栏。
struct WindowRootView: View {
    @State private var workspace = Workspace()
    @State private var localization = LocalizationService.shared

    var body: some View {
        VStack(spacing: 0) {
            if let banner = workspace.banner {
                BannerView(banner: banner) {
                    workspace.dismissBanner()
                }
            }
            editorArea
            if workspace.showStatusBar {
                StatusBarView(workspace: workspace)
            }
        }
        .frame(
            minWidth: WindowRootView.minimumWindowSize.width,
            maxWidth: .infinity,
            minHeight: WindowRootView.minimumWindowSize.height,
            maxHeight: .infinity
        )
        .background(
            WindowAccessor { window in
                workspace.bind(window: window)
            }
        )
        .focusedSceneValue(\.commandRouter, workspace)
        .onChange(of: localization.language) { _ in
            workspace.refreshStatusMetrics()
        }
    }

    /// 最小窗口尺寸，对齐 devplaybook/PROJECT/UI_STYLE.md。
    static let minimumWindowSize = CGSize(width: 480, height: 320)

    @ViewBuilder
    private var editorArea: some View {
        if let document = workspace.store.currentDocument {
            EditorScrollView(document: document, workspace: workspace)
                .id(document.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            emptyState
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var emptyState: some View {
        VStack(spacing: UIConstants.spacingStandard) {
            Text(localization.string("app.name"))
                .font(.headline)
            Text(localization.string("app.tagline"))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(localization.string("document.new")) {
                workspace.newDocument()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// 顶部提示条（T-016 大文件警告等）。
struct BannerView: View {
    let banner: Workspace.Banner
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: UIConstants.spacingCompact) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
            Spacer()
            Button(LocalizationSnapshot.string("banner.dismiss"), action: onDismiss)
                .controlSize(.small)
        }
        .padding(.horizontal, UIConstants.spacingStandard)
        .padding(.vertical, UIConstants.spacingCompact)
        .background(Color.yellow.opacity(0.12))
    }

    private var message: String {
        switch banner {
        case let .largeFileWarning(byteCount):
            let formatted = ByteCount.format(byteCount)
            return String(
                format: LocalizationSnapshot.string("banner.largeFileWarning"),
                formatted
            )
        }
    }
}
