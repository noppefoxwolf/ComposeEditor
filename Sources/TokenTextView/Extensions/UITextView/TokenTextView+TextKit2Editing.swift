import UIKit

// MARK: - TextKit 2 Editing

extension TokenTextView {
    func performTextKit2Editing(_ edits: () -> Void) {
        guard let textContentManager = textLayoutManager?.textContentManager else {
            preconditionFailure("TokenTextView requires a TextKit 2 text content manager.")
        }
        textContentManager.performEditingTransaction(edits)
    }

    func notifyEditingStateChange() {
        tokenDelegate?.tokenTextViewDidChangeEditingState(self)
    }
}

extension UITextView {
    func assertUsesTextKit2() {
        precondition(textLayoutManager != nil, "TokenTextView requires TextKit 2.")
    }
}
