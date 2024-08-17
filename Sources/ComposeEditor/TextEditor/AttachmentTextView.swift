import Combine
import UIKit

open class AttachmentTextView: NativePlaceholderTextView {
    public let leadingAttachmentsView = UIStackView()
    final class LeadingAttachmentConstraints: Sendable {
        var leading: NSLayoutConstraint? = nil
        var top: NSLayoutConstraint? = nil
    }
    var leadingAttachmentConstraints = LeadingAttachmentConstraints()
    
    
    public let bottomAttachmentsView = UIStackView()
    final class BottomAttachmentConstraints: Sendable {
        var leading: NSLayoutConstraint? = nil
        var trailing: NSLayoutConstraint? = nil
        var bottom: NSLayoutConstraint? = nil
    }
    var bottomAttachmentConstraints = BottomAttachmentConstraints()
    
    var cancellables: Set<AnyCancellable> = []

    open override var textContainerInset: UIEdgeInsets {
        didSet { applyInset() }
    }
    
    public var leadingAttachmentInset: UIEdgeInsets = UIEdgeInsets(
        top: 6,
        left: 6,
        bottom: 0,
        right: 6
    )
    {
        didSet { applyInset() }
    }

    public var bottomAttachmentInset: UIEdgeInsets = UIEdgeInsets(
        top: 6,
        left: 0,
        bottom: 6,
        right: 0
    )
    {
        didSet { applyInset() }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        leadingAttachmentsView.axis = .vertical
        leadingAttachmentsView.spacing = UIStackView.spacingUseSystem
        addSubview(leadingAttachmentsView)
        
        leadingAttachmentsView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomAttachmentsView.axis = .vertical
        bottomAttachmentsView.spacing = UIStackView.spacingUseSystem
        addSubview(bottomAttachmentsView)

        bottomAttachmentsView.translatesAutoresizingMaskIntoConstraints = false
        
        leadingAttachmentConstraints.leading = leadingAttachmentsView.leadingAnchor.constraint(equalTo: leadingAnchor)
        leadingAttachmentConstraints.top = leadingAttachmentsView.topAnchor.constraint(equalTo: textInputView.topAnchor)
        NSLayoutConstraint.activate([
            leadingAttachmentConstraints.leading,
            leadingAttachmentConstraints.top,
        ].compactMap({ $0 }))

        bottomAttachmentConstraints.leading = bottomAttachmentsView.leadingAnchor.constraint(
            equalTo: textInputView.leadingAnchor
        )
        bottomAttachmentConstraints.trailing = textInputView.trailingAnchor.constraint(
            equalTo: bottomAttachmentsView.trailingAnchor
        )
        bottomAttachmentConstraints.bottom = textInputView.bottomAnchor.constraint(
            equalTo: bottomAttachmentsView.bottomAnchor
        )
        NSLayoutConstraint.activate(
            [
                bottomAttachmentConstraints.bottom,
                bottomAttachmentConstraints.leading,
                bottomAttachmentConstraints.trailing,
            ]
            .compactMap({ $0 })
        )
        
        leadingAttachmentsView.publisher(for: \.bounds)
            .sink { [weak self] rect in
                self?.applyAttachmentSize()
            }
            .store(in: &cancellables)

        bottomAttachmentsView.publisher(for: \.bounds)
            .sink { [weak self] rect in
                self?.applyAttachmentSize()
            }
            .store(in: &cancellables)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyInset() {
        guard bounds.size.width > 0 else { return }
        leadingAttachmentConstraints.top?.constant = leadingAttachmentInset.top
        leadingAttachmentConstraints.leading?.constant = leadingAttachmentInset.left
        bottomAttachmentConstraints.bottom?.constant = bottomAttachmentInset.bottom
        bottomAttachmentConstraints.leading?.constant = textContainerInset.left + textContainer.lineFragmentPadding
        bottomAttachmentConstraints.trailing?.constant = textContainerInset.right
        setNeedsLayout()
    }

    func applyAttachmentSize() {
        // should less than visible height
        var bottomInset: Double = bottomAttachmentInset.top
        bottomInset += bottomAttachmentsView.bounds.height
        bottomInset += bottomAttachmentInset.bottom
        textContainerInset.bottom = bottomInset
        
        var leftInset: Double = leadingAttachmentInset.left
        leftInset += leadingAttachmentsView.bounds.width
        leftInset += leadingAttachmentInset.right
        textContainerInset.left = leftInset
        
        textContainerInset.right = 0
    }
}
