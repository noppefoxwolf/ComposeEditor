import Combine
import UIKit

open class AttachmentTextView: NativePlaceholderTextView {
    public let bottomAttachmentsView = UIStackView()
    public let leadingAttachmentsView = UIStackView()
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupViews()
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        leadingAttachmentsView.axis = .vertical
        leadingAttachmentsView.spacing = UIStackView.spacingUseSystem
        leadingAttachmentsView.layoutMargins = .init(top: 6, left: 6, bottom: 0, right: 6)
        leadingAttachmentsView.isLayoutMarginsRelativeArrangement = true
        leadingAttachmentsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leadingAttachmentsView)
        NSLayoutConstraint.activate([
            leadingAttachmentsView.topAnchor.constraint(
                equalTo: textInputView.topAnchor
            ),
            leadingAttachmentsView.leadingAnchor.constraint(
                equalTo: textInputView.leadingAnchor
            ),
        ])
        
        bottomAttachmentsView.axis = .vertical
        bottomAttachmentsView.spacing = UIStackView.spacingUseSystem
        bottomAttachmentsView.layoutMargins = .init(top: 6, left: 0, bottom: 6, right: 0)
        bottomAttachmentsView.isLayoutMarginsRelativeArrangement = true
        bottomAttachmentsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomAttachmentsView)
        NSLayoutConstraint.activate([
            bottomAttachmentsView.bottomAnchor.constraint(
                equalTo: textInputView.bottomAnchor
            ),
            bottomAttachmentsView.leadingAnchor.constraint(
                equalTo: textInputView.leadingAnchor
            ),
            bottomAttachmentsView.trailingAnchor.constraint(
                equalTo: textInputView.trailingAnchor
            ),
        ])
        
        alwaysBounceVertical = true
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        textContainerInset.left = leadingAttachmentsView.frame.width
        textContainerInset.bottom = bottomAttachmentsView.frame.height
        bottomAttachmentsView.layoutMargins.left = leadingAttachmentsView.frame.width + textContainer.lineFragmentPadding
    }
}
