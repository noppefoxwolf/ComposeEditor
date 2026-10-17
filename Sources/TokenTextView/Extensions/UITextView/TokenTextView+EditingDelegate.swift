import UIKit

// MARK: - Editing Delegate Forwarding

extension TokenTextView {
    /// Forward `UITextViewDelegate.textViewDidChange(_:)` here from the host delegate.
    public func handleTextViewDidChange(_ textView: UITextView) {
        textView.assertUsesTextKit2()
        guard !isReplacingMatches else { return }
        guard textView.markedTextRange == nil else {
            if pendingEditRange == nil {
                requiresFullScanAfterMarkedText = true
            }
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
        let replacementLength = replacementText.utf16.count
        if let pendingRange = pendingEditRange {
            // Move the accumulated range into the coordinates after this replacement.
            let delta = replacementLength - range.length
            let start = min(pendingRange.location, range.location)
            let previousEnd = NSMaxRange(pendingRange)
            let adjustedEnd: Int
            if previousEnd <= range.location {
                adjustedEnd = previousEnd
            } else if previousEnd >= NSMaxRange(range) {
                adjustedEnd = previousEnd + delta
            } else {
                adjustedEnd = range.location + replacementLength
            }
            let end = max(adjustedEnd, range.location + replacementLength)
            pendingEditRange = NSRange(location: start, length: end - start)
        } else {
            pendingEditRange = NSRange(location: range.location, length: replacementLength)
        }
        return true
    }
}
