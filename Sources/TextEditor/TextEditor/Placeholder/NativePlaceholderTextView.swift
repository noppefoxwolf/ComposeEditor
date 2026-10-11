import UIKit

// https://twitter.com/sebjvidal/status/1749160977948361020?s=61&t=mzhQQHpGIvp2La7c3d5MGg
// https://x.com/sebjvidal/status/1749162638573961383?s=46
open class NativePlaceholderTextView: UITextView {
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        font = .preferredFont(forTextStyle: .body)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var placeholder: String? = nil {
        didSet {
            let string = placeholder.map(NSAttributedString.init)
            let selector = Selector(("setAttributedPlaceholder:"))
            if responds(to: selector) {
                perform(selector, with: string)
            }
        }
    }
}
