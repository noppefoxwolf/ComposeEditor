import UIKit

// MARK: - Editing Delegate Forwarding

extension TokenTextView {
    /// Forward `UITextViewDelegate.textViewDidChange(_:)` here from the host delegate.
    public func handleTextViewDidChange(_ textView: UITextView) {
        textView.assertUsesTextKit2()
        guard !isReplacingMatches else { return }
        guard textView.markedTextRange == nil else {
            requiresFullScanAfterMarkedText = true
            notifyEditingStateChange()
            return
        }
        guard window != nil else {
            requiresFullScanAfterMarkedText = true
            notifyEditingStateChange()
            return
        }
        let changedRange = pendingEditRange
        pendingEditRange = nil
        let shouldScanEntireDocument = requiresFullScanAfterMarkedText || changedRange == nil
        requiresFullScanAfterMarkedText = false
        replaceMatches(in: shouldScanEntireDocument ? nil : changedRange, registersUndo: true)
        applyBehaviorAttributes(in: shouldScanEntireDocument ? nil : changedRange)
        tokenDelegate?.tokenTextView(
            self,
            didChangeTextIn: shouldScanEntireDocument ? nil : changedRange
        )
        notifyEditingStateChange()
    }

    /// Forward `UITextViewDelegate.textViewDidChangeSelection(_:)` here from the host delegate.
    public func handleTextViewDidChangeSelection(_ textView: UITextView) {
        textView.assertUsesTextKit2()
        guard !isReplacingMatches else { return }
        updateTypingAttributesForegroundColor()
        notifyEditingStateChange()
    }

    /// Forward `UITextViewDelegate.textView(_:shouldChangeTextIn:replacementText:)` here.
    /// Return this value from the host delegate's matching callback.
    public func shouldChangeText(in range: NSRange, replacementText: String) -> Bool {
        let textView = self
        textView.assertUsesTextKit2()
        if pendingEditRange != nil {
            requiresFullScanAfterMarkedText = true
        } else {
            pendingEditRange = NSRange(
                location: range.location,
                length: replacementText.utf16.count
            )
        }
        if textView.markedTextRange != nil {
            requiresFullScanAfterMarkedText = true
        }
        return true
    }
}
