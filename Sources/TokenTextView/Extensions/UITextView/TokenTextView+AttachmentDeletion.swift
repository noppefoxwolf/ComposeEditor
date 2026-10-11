import UIKit

// MARK: - Attachment Deletion

extension TokenTextView {
    func expandMarkedAttachmentBeforeCaret() -> Bool {
        guard markedTextRange == nil,
              selectedRange.length == 0,
              selectedRange.location > 0,
              let attachment = textStorage.markedAttachment(
                atUTF16Location: selectedRange.location - 1
              ),
              let replacement = textStorage.literalReplacement(
                for: attachment,
                removingFinalCharacter: true
              ) else {
            return false
        }

        let originalText = NSAttributedString(attributedString: textStorage)
        let originalSelection = selectedRange
        registerUndo(toRestore: originalText, selection: originalSelection)

        isReplacingMatches = true
        performTextKit2Editing {
            textStorage.replaceCharacters(in: replacement.range, with: replacement.text)
        }
        isReplacingMatches = false
        selectedRange = NSRange(location: replacement.range.location + replacement.text.length, length: 0)
        applyBehaviorAttributes(in: replacement.range)
        tokenDelegate?.tokenTextView(self, didChangeTextIn: replacement.range)
        notifyEditingStateChange()
        return true
    }
}
