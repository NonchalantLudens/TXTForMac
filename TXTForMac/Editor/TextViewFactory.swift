import AppKit

/// 文本视图工厂：按文档与当前设置产出配置一致的 `NSTextView`。
@MainActor
enum TextViewFactory {
    static func makeTextView(
        for document: Document,
        settings: AppSettings,
        coordinator: EditorCoordinator
    ) -> NSTextView {
        let textView = NSTextView()
        configurePlainTextView(textView, settings: settings)
        applyTheme(to: textView, settings: settings)
        applyWordWrap(settings.defaultWordWrap, to: textView)
        applyZoom(document.zoomScale, to: textView, settings: settings)
        textView.delegate = coordinator
        textView.isEditable = !document.isReadOnly
        document.drainPendingText(into: textView)
        return textView
    }

    /// 纯文本语义：关闭富文本与各类智能替换（US-003：还原记事本行为）。
    private static func configurePlainTextView(_ textView: NSTextView, settings: AppSettings) {
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = !settings.defaultWordWrap
        textView.autoresizingMask = settings.defaultWordWrap ? [.width] : []
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = settings.defaultWordWrap
        textView.textContainer?.containerSize = NSSize(
            width: settings.defaultWordWrap ? 0 : CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.lineFragmentPadding = 4
    }

    private static func applyTheme(to textView: NSTextView, settings: AppSettings) {
        textView.backgroundColor = EditorTheme.background
        textView.insertionPointColor = EditorTheme.caret
        textView.selectedTextAttributes = [
            .backgroundColor: EditorTheme.selection,
        ]
        let fontSize = CGFloat(settings.editorFontSize)
        let font: NSFont = if settings.editorUseMonospacedFont {
            .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        } else {
            .systemFont(ofSize: fontSize)
        }
        textView.font = font
        textView.textColor = EditorTheme.foreground
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: EditorTheme.foreground,
        ]
        textView.defaultParagraphStyle = defaultParagraphStyle(settings: settings)
    }

    static func defaultParagraphStyle(settings: AppSettings) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = CGFloat(settings.editorLineSpacing)
        style.defaultTabInterval = CGFloat(settings.tabWidth) * 8
        return style
    }

    static func applyWordWrap(_ enabled: Bool, to textView: NSTextView) {
        textView.isHorizontallyResizable = !enabled
        textView.autoresizingMask = enabled ? [.width] : []
        textView.textContainer?.widthTracksTextView = enabled
        textView.textContainer?.containerSize = NSSize(
            width: enabled ? 0 : CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.needsLayout = true
    }

    static func applyZoom(_ scale: CGFloat, to textView: NSTextView, settings _: AppSettings) {
        guard let base = textView.font else { return }
        let scaled = base.withSize(base.pointSize * scale) ?? base
        textView.font = scaled
        textView.needsDisplay = true
    }
}
