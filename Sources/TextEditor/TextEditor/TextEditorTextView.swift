import UIKit

open class TextEditorTextView: PasteboardActionTextView {
    public lazy var virtualKeyboard: VirtualKeyboard = {
        let virtualKeyboard = VirtualKeyboard()
        virtualKeyboard.textView = self
        return virtualKeyboard
    }()
}
