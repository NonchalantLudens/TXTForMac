import AppKit
import FinderSync
import SwiftUI

/// 设置窗口（T-033..T-036）：⌘, 打开，全部设置即时生效（写入走 SettingsStore 单一出口）。
struct SettingsRootView: View {
    @State private var store = SettingsStore.shared

    var body: some View {
        TabView {
            GeneralPane(store: store)
                .tabItem { Label(Settings.text("settings.tab.general"), systemImage: "gearshape") }
            EditorPane(store: store)
                .tabItem { Label(Settings.text("settings.tab.editor"), systemImage: "textformat") }
            FilesPane(store: store)
                .tabItem { Label(Settings.text("settings.tab.files"), systemImage: "doc") }
            AppearancePane(store: store)
                .tabItem { Label(Settings.text("settings.tab.appearance"), systemImage: "paintbrush") }
            FinderPane(store: store)
                .tabItem { Label(Settings.text("settings.tab.finder"), systemImage: "menubar.dock.rectangle") }
            UpdatePane(store: store)
                .tabItem { Label(Settings.text("settings.tab.update"), systemImage: "arrow.triangle.2.circlepath") }
            AboutPane()
                .tabItem { Label(Settings.text("settings.tab.about"), systemImage: "info.circle") }
        }
        .frame(width: 520, height: 380)
    }
}

@MainActor
private enum Settings {
    static func text(_ key: String) -> String {
        LocalizationSnapshot.string(key)
    }
}

extension SettingsStore {
    /// 设置页专用绑定投影：读直接取值，写仍收敛到 `update()`（ADR-004 单一出口）。
    func binding<W>(_ keyPath: WritableKeyPath<AppSettings, W>) -> Binding<W> {
        Binding<W>(
            get: { [self] in settings[keyPath: keyPath] },
            set: { [self] newValue in
                update { settingsValue in
                    settingsValue[keyPath: keyPath] = newValue
                }
            }
        )
    }
}

// MARK: - 通用

private struct GeneralPane: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Picker(Settings.text("settings.language"), selection: store.binding(\.interfaceLanguage)) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(Settings.text("language.\(language.rawValue)")).tag(language)
                }
            }
            Picker(Settings.text("settings.launchBehavior"), selection: store.binding(\.launchBehavior)) {
                ForEach(LaunchBehavior.allCases, id: \.self) { behavior in
                    Text(Settings.text("launch.\(behavior.rawValue)")).tag(behavior)
                }
            }
            TextField(Settings.text("settings.defaultNewFileName"), text: store.binding(\.defaultNewFileName))
            HStack {
                TextField(
                    Settings.text("settings.defaultFileExtension"),
                    text: store.binding(\.defaultFileExtension)
                )
                .frame(width: 100)
            }
            Button(Settings.text("settings.setDefaultEditor")) {
                registerAsDefaultEditor()
            }
        }
        .padding(UIConstants.spacingLoose)
    }

    /// 用一个临时 txt 文件把本应用注册为默认文本编辑器（T-036，macOS 12+ 公开 API）。
    private func registerAsDefaultEditor() {
        guard let appURL = Bundle.main.bundleURL as URL?,
              let sample = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
              .appendingPathComponent("TXTForMac-SetDefault.txt") else { return }
        if !FileManager.default.fileExists(atPath: sample.path) {
            try? Data().write(to: sample)
        }
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenFileAt: sample) { error in
            Task { @MainActor in
                if let error {
                    NSApp.presentError(error)
                }
            }
        }
    }
}

// MARK: - 编辑

private struct EditorPane: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Toggle(Settings.text("settings.monoFont"), isOn: store.binding(\.editorUseMonospacedFont))
            Stepper(
                "\(Settings.text("settings.fontSize")): \(Int(store.settings.editorFontSize))",
                value: store.binding(\.editorFontSize), in: 8 ... 48, step: 1
            )
            Stepper(
                "\(Settings.text("settings.lineSpacing")): \(Int(store.settings.editorLineSpacing))",
                value: store.binding(\.editorLineSpacing), in: 0 ... 24, step: 1
            )
            Stepper(
                "\(Settings.text("settings.tabWidth")): \(store.settings.tabWidth)",
                value: store.binding(\.tabWidth), in: 1 ... 16, step: 1
            )
            Toggle(Settings.text("menu.format.wordWrap"), isOn: store.binding(\.defaultWordWrap))
            Toggle(Settings.text("settings.autoIndent"), isOn: store.binding(\.autoIndent))
            Toggle(Settings.text("settings.pasteWithoutFormatting"), isOn: store.binding(\.pasteWithoutFormatting))
        }
        .padding(UIConstants.spacingLoose)
    }
}

// MARK: - 文件

private struct FilesPane: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Toggle(Settings.text("settings.autoSave"), isOn: store.binding(\.autoSaveEnabled))
            Stepper(
                "\(Settings.text("settings.autoSaveInterval")): \(store.settings.autoSaveIntervalSeconds)s",
                value: store.binding(\.autoSaveIntervalSeconds), in: 1 ... 120, step: 1
            )
            .disabled(!store.settings.autoSaveEnabled)
            Toggle(Settings.text("settings.saveSession"), isOn: store.binding(\.saveSessionOnClose))
            Stepper(
                "\(Settings.text("settings.recentFilesLimit")): \(store.settings.recentFilesLimit)",
                value: store.binding(\.recentFilesLimit), in: 0 ... 20, step: 1
            )
            Toggle(Settings.text("settings.backup"), isOn: store.binding(\.createBackupFile))
        }
        .padding(UIConstants.spacingLoose)
    }
}

// MARK: - 外观

private struct AppearancePane: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Picker(Settings.text("menu.view.appearance"), selection: store.binding(\.theme)) {
                ForEach(ThemePreference.allCases, id: \.self) { preference in
                    Text(Settings.text("theme.\(preference.rawValue)")).tag(preference)
                }
            }
            Toggle(Settings.text("settings.showTabBar"), isOn: store.binding(\.showTabBar))
            Toggle(Settings.text("settings.showStatusBar"), isOn: store.binding(\.showStatusBar))
        }
        .padding(UIConstants.spacingLoose)
        .onChange(of: store.settings.theme) { newValue in
            Workspace.applyAppearanceGlobally(newValue)
        }
    }
}

// MARK: - 右键集成

private struct FinderPane: View {
    @Bindable var store: SettingsStore
    @State private var extensionEnabled = FIFinderSyncController.isExtensionEnabled

    var body: some View {
        Form {
            LabeledContent(
                Settings.text("settings.finderStatus"),
                value: extensionEnabled
                    ? Settings.text("settings.finderStatus.enabled")
                    : Settings.text("settings.finderStatus.disabled")
            )
            .onAppear { extensionEnabled = FIFinderSyncController.isExtensionEnabled }
            Toggle(Settings.text("settings.finderEnabled"), isOn: store.binding(\.finderExtensionEnabled))
            HStack {
                Text(Settings.text("settings.finderDirectories"))
                Spacer()
                Button(Settings.text("settings.finderAddDirectory")) { addDirectory() }
                    .disabled(!store.settings.finderExtensionEnabled)
            }
            ForEach(store.settings.finderMonitoredDirectories, id: \.self) { path in
                HStack {
                    Text((path as NSString).lastPathComponent)
                        .font(.callout)
                        .help(path)
                    Spacer()
                    Button(Settings.text("settings.finderRemove")) {
                        store.update { settings in
                            settings.finderMonitoredDirectories.removeAll { $0 == path }
                        }
                    }
                    .controlSize(.small)
                }
            }
            TextField(
                Settings.text("settings.finderMenuTitle"),
                text: store.binding(\.finderMenuItemTitle)
            )
            .disabled(!store.settings.finderExtensionEnabled)
            TextField(
                Settings.text("settings.finderExtensionName"),
                text: store.binding(\.finderNewFileExtension)
            )
            .frame(width: 120)
            .disabled(!store.settings.finderExtensionEnabled)
            Picker(
                Settings.text("settings.finderConflictPolicy"),
                selection: store.binding(\.finderNamingConflictPolicy)
            ) {
                ForEach(NamingConflictPolicy.allCases, id: \.self) { policy in
                    Text(Settings.text("policy.\(policy.rawValue)")).tag(policy)
                }
            }
            .disabled(!store.settings.finderExtensionEnabled)
            Button(Settings.text("settings.finderOpenSystemSettings")) {
                openExtensionSettings()
            }
        }
        .padding(UIConstants.spacingLoose)
    }

    private func addDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.update { settings in
            if !settings.finderMonitoredDirectories.contains(url.path) {
                settings.finderMonitoredDirectories.append(url.path)
            }
        }
    }

    private func openExtensionSettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.LoginExtensions-Settings.extension"
        ) ?? URL(string: "x-apple.systempreferences:com.apple.extensions.settings")!
        NSWorkspace.shared.open(url)
    }
}

// MARK: - 更新

private struct UpdatePane: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Picker(Settings.text("settings.updateFrequency"), selection: store.binding(\.updateCheckFrequency)) {
                ForEach(CheckUpdateFrequency.allCases, id: \.self) { frequency in
                    Text(Settings.text("update.\(frequency.rawValue)")).tag(frequency)
                }
            }
            Picker(Settings.text("settings.updateChannel"), selection: store.binding(\.updateChannel)) {
                ForEach(UpdateChannel.allCases, id: \.self) { channel in
                    Text(Settings.text("channel.\(channel.rawValue)")).tag(channel)
                }
            }
            LabeledContent(
                Settings.text("settings.currentVersion"),
                value: Bundle.main.object(
                    forInfoDictionaryKey: "CFBundleShortVersionString"
                ) as? String ?? "-"
            )
            Button(Settings.text("settings.checkNow")) {
                UpdaterService.shared.checkForUpdates()
            }
            .onChange(of: store.settings.updateCheckFrequency) { newValue in
                UpdaterService.shared.applyScheduledInterval(newValue)
            }
        }
        .padding(UIConstants.spacingLoose)
    }
}

// MARK: - 关于

private struct AboutPane: View {
    var body: some View {
        VStack(spacing: UIConstants.spacingStandard) {
            Text(LocalizationSnapshot.string("app.name"))
                .font(.title2)
            Text(LocalizationSnapshot.string("app.tagline"))
                .font(.footnote)
                .foregroundStyle(.secondary)
            ScrollView {
                Text(LocalizationSnapshot.string("about.license"))
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 130)
            Button(Settings.text("about.openRepository")) {
                if let url = URL(string: SettingsSchema.githubRepositoryURL) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(UIConstants.spacingLoose)
    }
}
