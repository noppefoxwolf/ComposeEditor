import UIKit

// MARK: - Marked Text Clipboard

extension TokenTextView {
    func markedTextAwareStringForSelection() -> String? {
        let selection = selectedRange
        guard selection.length > 0 else { return nil }
        return textStorage.plainTextReplacingMarkedAttachments(in: selection)
    }
}
