import UIKit

// MARK: - Undoable Text Storage Changes

extension TokenTextView {
    func registerUndo(toRestore text: NSAttributedString, selection: NSRange) {
        undoManager?.registerUndo(withTarget: self) { textView in
            textView.restoreTextStorage(text, selection: selection)
        }
    }

    private func restoreTextStorage(_ text: NSAttributedString, selection: NSRange) {
        let currentText = NSAttributedString(attributedString: textStorage)
        let currentSelection = selectedRange
        registerUndo(toRestore: currentText, selection: currentSelection)

        isReplacingMatches = true
        performTextKit2Editing {
            textStorage.beginEditing()
            textStorage.replaceCharacters(
                in: NSRange(location: 0, length: textStorage.length),
                with: text
            )
            textStorage.endEditing()
        }
        isReplacingMatches = false
        let location = max(0, min(selection.location, textStorage.length))
        selectedRange = NSRange(
            location: location,
            length: max(0, min(selection.length, textStorage.length - location))
        )
        notifyEditingStateChange()
    }
}
