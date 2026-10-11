import UIKit

open class InputAccessoryHostingTextView: AttachmentTextView {
    #if os(iOS)
    var _inputAccessoryViewController: UIInputViewController? = nil
    public override var inputAccessoryViewController: UIInputViewController? {
        get {
            if let _inputAccessoryViewController {
                return _inputAccessoryViewController
            }
            return super.inputAccessoryViewController
        }
        set {
            _inputAccessoryViewController = newValue
        }
    }
    #endif

    var _inputViewController: UIInputViewController? = nil
    public override var inputViewController: UIInputViewController? {
        get {
            if let _inputViewController {
                return _inputViewController
            }
            return super.inputViewController
        }
        set {
            _inputViewController = newValue
        }
    }
}
