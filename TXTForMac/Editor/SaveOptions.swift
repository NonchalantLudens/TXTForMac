import AppKit
import SwiftUI

/// 「另存为」面板附加选项（T-015）：编码 / 换行符 / BOM。
@MainActor
@Observable
final class SaveOptions {
    var encoding: TextEncoding
    var lineEnding: LineEnding
    var writeBOM: Bool

    init(encoding: TextEncoding, lineEnding: LineEnding, writeBOM: Bool) {
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.writeBOM = writeBOM
    }
}

/// 承载附加选项的 AppKit 容器。
@MainActor
final class SaveOptionsController {
    let options: SaveOptions
    private let hostingView: NSHostingView<SaveOptionsView>

    var view: NSView {
        hostingView
    }

    init(options: SaveOptions) {
        self.options = options
        hostingView = NSHostingView(
            rootView: SaveOptionsView(options: options)
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 96)
    }
}

struct SaveOptionsView: View {
    @Bindable var options: SaveOptions

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.spacingCompact) {
            Picker(
                LocalizationSnapshot.string("save.encoding"),
                selection: $options.encoding
            ) {
                ForEach(TextEncoding.allCases, id: \.self) { encoding in
                    Text(LocalizationSnapshot.string(encoding.localizationKey))
                        .tag(encoding)
                }
            }
            Picker(
                LocalizationSnapshot.string("save.lineEnding"),
                selection: $options.lineEnding
            ) {
                ForEach(LineEnding.allCases, id: \.self) { ending in
                    Text(LocalizationSnapshot.string(ending.localizationKey))
                        .tag(ending)
                }
            }
            Toggle(
                LocalizationSnapshot.string("save.writeBOM"),
                isOn: $options.writeBOM
            )
        }
        .pickerStyle(.menu)
        .padding(UIConstants.spacingStandard)
        .frame(width: 320)
    }
}
