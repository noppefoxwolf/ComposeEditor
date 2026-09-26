import UIKit

open class PasteboardActionTextView: InputAccessoryHostingTextView {
    public var copyAction: ((UITextView) -> Void)? = nil
    public var onCopy: ((UITextView) -> Void)? = nil
    
    public var cutAction: ((UITextView) -> Void)? = nil
    public var onCut: ((UITextView) -> Void)? = nil
    
    public var pasteAction: ((UITextView) -> Void)? = nil
    public var onPaste: ((UITextView) -> Void)? = nil
    
    open override func copy(_ sender: Any?) {
        if let copyAction {
            copyAction(self)
        } else {
            super.copy(sender)
        }
        onCopy?(self)
    }
    
    open override func cut(_ sender: Any?) {
        if let cutAction {
            cutAction(self)
        } else {
            super.cut(sender)
        }
        onCut?(self)
    }
    
    open override func paste(_ sender: Any?) {
        if let pasteAction {
            pasteAction(self)
        } else {
            super.paste(sender)
        }
        onPaste?(self)
    }
}
