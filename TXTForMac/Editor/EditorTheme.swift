import AppKit
import SwiftUI

/// 编辑器配色 token（ADR-006）。
///
/// 基线值全部来自 Asset Catalog Color Set（亮暗两套）或系统语义色；
/// 这里是整个工程唯一的 NSColor 构造点（`NSColor.init` 形式，满足
/// 「颜色不得散落字面量」的约束意图），用户覆盖值在 T-037 注入。
@MainActor
enum EditorTheme {
    static var background: NSColor {
        namedColor("EditorBackground") ?? .textBackgroundColor
    }

    static var foreground: NSColor {
        namedColor("EditorForeground") ?? .textColor
    }

    static var selection: NSColor {
        .selectedTextBackgroundColor
    }

    static var caret: NSColor {
        .controlAccentColor
    }

    static var findHighlight: NSColor {
        namedColor("FindHighlight") ?? .findHighlightColor
    }

    static var findHighlightActive: NSColor {
        namedColor("FindHighlightActive") ?? .controlAccentColor
    }

    private static func namedColor(_ name: String) -> NSColor? {
        NSColor(named: name)
    }
}
