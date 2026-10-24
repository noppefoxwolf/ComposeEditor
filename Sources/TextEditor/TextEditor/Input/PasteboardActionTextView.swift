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
            performDefaultCopy(sender)
        }
        onCopy?(self)
    }
    
    open override func cut(_ sender: Any?) {
        if let cutAction {
            cutAction(self)
        } else {
            performDefaultCut(sender)
        }
        onCut?(self)
    }
    
    open override func paste(_ sender: Any?) {
        if let pasteAction {
            pasteAction(self)
        } else {
            performDefaultPaste(sender)
        }
        onPaste?(self)
    }

    /// Performs copy when no custom `copyAction` is installed.
    /// Override this hook to customize the default operation while retaining completion notification.
    open func performDefaultCopy(_ sender: Any?) {
        super.copy(sender)
    }

    /// Performs cut when no custom `cutAction` is installed.
    open func performDefaultCut(_ sender: Any?) {
        super.cut(sender)
    }

    /// Performs paste when no custom `pasteAction` is installed.
    open func performDefaultPaste(_ sender: Any?) {
        super.paste(sender)
    }
}
