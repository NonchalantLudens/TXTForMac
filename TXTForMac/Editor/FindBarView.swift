import SwiftUI

/// 查找 / 替换 / 转到行共用的顶部工具条（T-017/T-018/T-019）。
struct FindBarView: View {
    @Bindable var find: FindSession
    let workspace: Workspace

    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: UIConstants.spacingCompact) {
            content
            Spacer(minLength: 0)
            optionsMenu
            Button {
                workspace.hideFindBar()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .help(LocalizationSnapshot.string("find.close"))
        }
        .padding(.horizontal, UIConstants.spacingStandard)
        .padding(.vertical, UIConstants.spacingCompact)
        .frame(height: UIConstants.findBarHeight + 8)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
        .onAppear { fieldFocused = true }
        .onExitCommand { workspace.hideFindBar() }
    }

    @ViewBuilder
    private var content: some View {
        switch workspace.findMode {
        case .find, .replace:
            findContent
        case .goToLine:
            goToLineContent
        case nil:
            EmptyView()
        }
    }

    private var findContent: some View {
        HStack(spacing: UIConstants.spacingCompact) {
            TextField(
                LocalizationSnapshot.string("find.placeholder"),
                text: $find.query
            )
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 180)
            .focused($fieldFocused)
            .onSubmit { workspace.findNext(direction: 1) }
            .onChange(of: find.query) { _ in
                workspace.refreshFindMatches()
            }

            if workspace.findMode == .replace {
                TextField(
                    LocalizationSnapshot.string("find.replacementPlaceholder"),
                    text: $find.replacement
                )
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 180)
                .onSubmit { workspace.replaceCurrent() }
            }

            Text(find.countDescription)
                .font(.caption)
                .foregroundStyle(find.isInvalidQuery ? Color.red : Color.secondary)
                .monospacedDigit()

            Button {
                workspace.findNext(direction: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)

            Button {
                workspace.findNext(direction: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)

            if workspace.findMode == .replace {
                Button(LocalizationSnapshot.string("find.replace")) {
                    workspace.replaceCurrent()
                }
                .controlSize(.small)

                Button(LocalizationSnapshot.string("find.replaceAll")) {
                    workspace.replaceAll()
                }
                .controlSize(.small)
            }
        }
    }

    private var goToLineContent: some View {
        HStack(spacing: UIConstants.spacingCompact) {
            Text(LocalizationSnapshot.string("goto.label"))
                .font(.callout)
            TextField(
                LocalizationSnapshot.string("goto.placeholder"),
                text: $find.lineText
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 90)
            .focused($fieldFocused)
            .onSubmit { workspace.goToLine() }
        }
    }

    private var optionsMenu: some View {
        Menu {
            optionToggle(LocalizationSnapshot.string("find.caseSensitive"), find.caseSensitive) {
                find.caseSensitive.toggle()
                workspace.refreshFindMatches()
            }
            optionToggle(LocalizationSnapshot.string("find.wholeWord"), find.wholeWord) {
                find.wholeWord.toggle()
                workspace.refreshFindMatches()
            }
            optionToggle(LocalizationSnapshot.string("find.regex"), find.isRegex) {
                find.isRegex.toggle()
                workspace.refreshFindMatches()
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func optionToggle(
        _ title: String,
        _ isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            if isActive {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }
}
