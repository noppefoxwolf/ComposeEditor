import UIKit

open class TextEditorTextView: PasteboardActionTextView {
    /// Prepares smart-inserted text before padding and delegate approval.
    open func textForInsertion(_ text: String, in range: UITextRange) -> String {
        text
    }

    public lazy var virtualKeyboard: VirtualKeyboard = {
        let virtualKeyboard = VirtualKeyboard()
        virtualKeyboard.textView = self
        return virtualKeyboard
    }()
}
