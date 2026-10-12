import UIKit
import TextEditor

/// A TextKit 2 text view that applies registered token detectors and their optional effects.
open class TokenTextView: TextEditorTextView {
    var behaviors: [any TokenBehavior] = []
    var isReplacingMatches = false
    var pendingEditRange: NSRange?
    var requiresFullScanAfterMarkedText = false
    var didPerformInitialTextScan = false
    var originalTypingForegroundColor: UIColor?
    var pasteboard = UIPasteboard.general

    /// Receives text and editing-state notifications. The host owns and retains the delegate.
    public weak var tokenDelegate: (any TokenTextViewDelegate)?

    /// The text content with TokenTextView-managed attachments restored to their original literals.
    /// This value is generated on demand and is suitable for saving or sending edited content.
    public var plainText: String {
        let range = NSRange(location: 0, length: textStorage.length)
        return textStorage.plainTextReplacingMarkedAttachments(in: range) ?? textStorage.string
    }

    /// Creates a TextKit 2 text view. Register behaviors before adding it to a window when possible.
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        precondition(textLayoutManager != nil, "TokenTextView requires TextKit 2.")
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        precondition(textLayoutManager != nil, "TokenTextView requires TextKit 2.")
    }

    /// Registers or replaces a behavior with the same detector identifier.
    public func register(_ behavior: any TokenBehavior) {
        precondition(behavior.detector.maximumTokenLength > 0, "maximumTokenLength must be positive.")
        if let index = behaviors.firstIndex(where: { $0.detector.identifier == behavior.detector.identifier }) {
            behaviors[index] = behavior
        } else {
            behaviors.append(behavior)
        }

        guard didPerformInitialTextScan else { return }
        replaceMatches()
        applyBehaviorAttributes(in: nil)
        tokenDelegate?.tokenTextView(self, didChangeTextIn: nil)
    }

    /// Removes a registered behavior by detector identifier. Its attachments are restored to text.
    public func unregisterBehavior(identifier: String) {
        behaviors.removeAll { $0.detector.identifier == identifier }
        guard didPerformInitialTextScan else { return }
        replaceMatches()
        applyBehaviorAttributes(in: nil)
        tokenDelegate?.tokenTextView(self, didChangeTextIn: nil)
    }

    /// Re-runs registered token detectors against the current text.
    /// Call this when a behavior's attachment provider can now resolve text that it previously left unchanged.
    public func refreshTokens() {
        replaceMatches()
        applyBehaviorAttributes(in: nil)
        tokenDelegate?.tokenTextView(self, didChangeTextIn: nil)
    }

    /// The active token context at the caret, for the app to use when searching suggestions.
    public var activeSuggestionContext: TokenSuggestionContext? {
        guard selectedRange.length == 0, markedTextRange == nil else { return nil }
        let text = textStorage.string
        let nsText = text as NSString
        for behavior in behaviors.sorted(by: { $0.detector.priority > $1.detector.priority }) {
            guard let contextSearch = behavior.detector.suggestionContextSearch,
                  let match = contextSearch(nsText, selectedRange) else { continue }
            return TokenSuggestionContext(
                behaviorIdentifier: behavior.detector.identifier,
                text: text,
                selectedRange: selectedRange,
                tokenRange: match.tokenRange,
                prefix: match.prefix,
                suffix: match.suffix
            )
        }
        return nil
    }

    /// Replaces the token in a suggestion context with the selected suggestion text.
    ///
    /// The context must still match the current suggestion context. Stale contexts are ignored.
    /// The replacement is sent through the text view's delegate and normal editing pipeline.
    public func applySuggestion(_ replacementText: String, for context: TokenSuggestionContext) {
        guard activeSuggestionContext == context,
              let tokenRange = Range(context.tokenRange, in: context.text) else {
            return
        }

        let replacementEndsAtDocumentEnd = NSMaxRange(context.tokenRange) == textStorage.length
        let replacementNeedsTrailingSpace = replacementEndsAtDocumentEnd
            && replacementText.last?.isWhitespace != true
        let appliedText = replacementNeedsTrailingSpace ? replacementText + " " : replacementText

        let originalColor = textStorage.attribute(
            .markedTextOriginalForegroundColor,
            at: context.tokenRange.location,
            effectiveRange: nil
        ) as? UIColor ?? originalTypingForegroundColor ?? textColor ?? .label
        originalTypingForegroundColor = originalColor
        var attributes = typingAttributes
        attributes[.foregroundColor] = originalColor
        typingAttributes = attributes

        virtualKeyboard.replaceText(tokenRange, withText: appliedText)

        let replacementRange = NSRange(
            location: context.tokenRange.location,
            length: appliedText.utf16.count
        )
        guard NSMaxRange(replacementRange) <= textStorage.length,
              textStorage.attributedSubstring(from: replacementRange).string == appliedText else {
            return
        }

        textStorage.removeAttribute(.markedTextOriginalForegroundColor, range: replacementRange)
        textStorage.addAttribute(.foregroundColor, value: originalColor, range: replacementRange)
        applyBehaviorAttributes(in: replacementRange)
        updateTypingAttributesForegroundColor()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !didPerformInitialTextScan else { return }
        didPerformInitialTextScan = true
        replaceMatches()
        applyBehaviorAttributes(in: nil)
        tokenDelegate?.tokenTextView(self, didChangeTextIn: nil)
        notifyEditingStateChange()
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        applyBehaviorAttributes(in: nil)
        tokenDelegate?.tokenTextView(self, didChangeTextIn: nil)
    }

    public override func deleteBackward() {
        guard !expandMarkedAttachmentBeforeCaret() else { return }
        super.deleteBackward()
    }

    public override func cut(_ sender: Any?) {
        if let cutAction {
            cutAction(self)
            onCut?(self)
            return
        }
        guard let copiedText = markedTextAwareStringForSelection() else {
            super.cut(sender)
            return
        }
        pasteboard.string = copiedText
        insertText("")
        onCut?(self)
    }

    public override func copy(_ sender: Any?) {
        if let copyAction {
            copyAction(self)
            onCopy?(self)
            return
        }
        guard let copiedText = markedTextAwareStringForSelection() else {
            super.copy(sender)
            return
        }
        pasteboard.string = copiedText
        onCopy?(self)
    }

    public override func paste(_ sender: Any?) {
        if let pasteAction {
            pasteAction(self)
            onPaste?(self)
            return
        }
        guard let pastedText = pasteboard.string else {
            super.paste(sender)
            return
        }
        insertText(pastedText)
        onPaste?(self)
    }
}

