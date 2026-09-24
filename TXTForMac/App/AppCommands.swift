import AppKit
import SwiftUI

/// 把当前 key window 的 Workspace 注册为菜单命令路由目标（T-013）。
struct CommandRouterFocusKey: FocusedValueKey {
    typealias Value = Workspace
}

extension FocusedValues {
    var commandRouter: Workspace? {
        get { self[CommandRouterFocusKey.self] }
        set { self[CommandRouterFocusKey.self] = newValue }
    }
}

/// 主菜单（T-013）。SwiftUI Commands 生成的即是 AppKit 菜单栏；
/// 查找/替换菜单在 T-017/T-018 落地后加入。
struct AppCommands: Commands {
    @FocusedValue(\.commandRouter) private var router: Workspace?

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button(LocalizationSnapshot.string("menu.app.checkUpdates")) {
                UpdaterService.shared.checkForUpdates()
            }
            .disabled(!UpdaterService.shared.canCheckForUpdates)
        }

        CommandGroup(replacing: .newItem) {
            Button(LocalizationSnapshot.string("menu.file.new")) {
                router?.newDocument()
            }
            .keyboardShortcut("n")

            Divider()

            Button(LocalizationSnapshot.string("menu.file.open")) {
                router?.openFiles()
            }
            .keyboardShortcut("o")
        }

        CommandGroup(after: .newItem) {
            Button(LocalizationSnapshot.string("menu.file.closeTab")) {
                router?.closeCurrentTab()
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
            .disabled(router?.store.isEmpty ?? true)
        }

        CommandGroup(replacing: .saveItem) {
            Button(LocalizationSnapshot.string("menu.file.save")) {
                router?.saveCurrent()
            }
            .keyboardShortcut("s")

            Button(LocalizationSnapshot.string("menu.file.saveAs")) {
                router?.saveAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: .undoRedo) {
            Button(LocalizationSnapshot.string("menu.edit.undo")) {
                router?.sendEditorAction(Selector(("undo:")))
            }
            .keyboardShortcut("z")

            Button(LocalizationSnapshot.string("menu.edit.redo")) {
                router?.sendEditorAction(Selector(("redo:")))
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
        }

        CommandGroup(after: .undoRedo) {
            Button(LocalizationSnapshot.string("menu.edit.cut")) {
                router?.sendEditorAction(#selector(NSText.cut(_:)))
            }
            .keyboardShortcut("x")

            Button(LocalizationSnapshot.string("menu.edit.copy")) {
                router?.sendEditorAction(#selector(NSText.copy(_:)))
            }
            .keyboardShortcut("c")

            Button(LocalizationSnapshot.string("menu.edit.paste")) {
                router?.sendEditorAction(#selector(NSText.paste(_:)))
            }
            .keyboardShortcut("v")

            Button(LocalizationSnapshot.string("menu.edit.pastePlain")) {
                router?.sendEditorAction(Selector(("pasteAsPlainText:")))
            }
            .keyboardShortcut("v", modifiers: [.command, .option])

            Divider()

            Button(LocalizationSnapshot.string("menu.edit.delete")) {
                router?.sendEditorAction(Selector(("delete:")))
            }
            .keyboardShortcut(.delete, modifiers: [])

            Button(LocalizationSnapshot.string("menu.edit.selectAll")) {
                router?.sendEditorAction(#selector(NSText.selectAll(_:)))
            }
            .keyboardShortcut("a")

            Divider()

            Button(LocalizationSnapshot.string("menu.edit.timeDate")) {
                router?.insertTimeDate()
            }
            .keyboardShortcut(KeyEquivalent("\u{F708}"), modifiers: [])
        }

        CommandMenu(LocalizationSnapshot.string("menu.find")) {
            Button(LocalizationSnapshot.string("menu.find.find")) {
                router?.beginFind()
            }
            .keyboardShortcut("f")

            Button(LocalizationSnapshot.string("menu.find.next")) {
                router?.findNext(direction: 1)
            }
            .keyboardShortcut("g")

            Button(LocalizationSnapshot.string("menu.find.previous")) {
                router?.findNext(direction: -1)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Divider()

            Button(LocalizationSnapshot.string("menu.find.replace")) {
                router?.beginReplace()
            }
            .keyboardShortcut("f", modifiers: [.command, .option])

            Divider()

            Button(LocalizationSnapshot.string("menu.find.goToLine")) {
                router?.beginGoToLine()
            }
            .keyboardShortcut("l")
        }

        CommandMenu(LocalizationSnapshot.string("menu.format")) {
            Button(LocalizationSnapshot.string("menu.format.wordWrap")) {
                router?.toggleWordWrap()
            }
            .keyboardShortcut("w", modifiers: [.command, .option])

            Divider()

            Button(LocalizationSnapshot.string("menu.format.font")) {
                router?.showFontPanel()
            }
            .keyboardShortcut("t")
        }

        CommandMenu(LocalizationSnapshot.string("menu.view")) {
            Button(LocalizationSnapshot.string("menu.view.zoomIn")) {
                router?.zoomIn()
            }
            .keyboardShortcut("+")

            Button(LocalizationSnapshot.string("menu.view.zoomOut")) {
                router?.zoomOut()
            }
            .keyboardShortcut("-")

            Button(LocalizationSnapshot.string("menu.view.zoomReset")) {
                router?.zoomReset()
            }
            .keyboardShortcut("0")

            Divider()

            Button(LocalizationSnapshot.string("menu.view.toggleStatusBar")) {
                router?.toggleStatusBar()
            }

            Picker(LocalizationSnapshot.string("menu.view.appearance"), selection: appearanceBinding) {
                ForEach(ThemePreference.allCases, id: \.self) { preference in
                    Text(LocalizationSnapshot.string("theme.\(preference.rawValue)"))
                        .tag(preference)
                }
            }
            .pickerStyle(.inline)
        }
    }

    private var appearanceBinding: Binding<ThemePreference> {
        Binding<ThemePreference>(
            get: { SettingsStore.shared.settings.theme },
            set: { newValue in
                SettingsStore.shared.update { settings in
                    settings.theme = newValue
                }
                router?.applyAppearance(newValue)
            }
        )
    }
}
