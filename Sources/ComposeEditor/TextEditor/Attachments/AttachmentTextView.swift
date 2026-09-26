import UIKit

open class AttachmentTextView: NativePlaceholderTextView {
    public let headerAttachmentsView = UIStackView()
    public let topAttachmentsView = UIStackView()
    public let bottomAttachmentsView = UIStackView()
    public let leadingAttachmentsView = UIStackView()

    private let attachmentLayoutView = AttachmentLayoutView()
    private let attachmentLayoutGuide = UILayoutGuide()
    private let leadingColumnGuide = UILayoutGuide()
    private let editorColumnGuide = UILayoutGuide()
    private var isUpdatingTextContainerInset = false
    private var lastAppliedAttachmentInsets: UIEdgeInsets?
    private lazy var emptyLeadingColumnWidthConstraint: NSLayoutConstraint = {
        let constraint = leadingColumnGuide.widthAnchor.constraint(equalToConstant: 0)
        constraint.priority = .fittingSizeLevel
        return constraint
    }()

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupViews()
    }

    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        configureStackViews()
        addLayoutGuides()
        addAttachmentViews()
        activateLayoutConstraints()

        alwaysBounceVertical = true
    }

    private func configureStackViews() {
        headerAttachmentsView.axis = .vertical
        headerAttachmentsView.spacing = UIStackView.spacingUseSystem
        headerAttachmentsView.layoutMargins = .init(top: 6, left: 0, bottom: 6, right: 0)
        headerAttachmentsView.isLayoutMarginsRelativeArrangement = true
        headerAttachmentsView.translatesAutoresizingMaskIntoConstraints = false

        leadingAttachmentsView.axis = .vertical
        leadingAttachmentsView.spacing = UIStackView.spacingUseSystem
        leadingAttachmentsView.layoutMargins = .init(top: 6, left: 6, bottom: 0, right: 6)
        leadingAttachmentsView.isLayoutMarginsRelativeArrangement = true
        leadingAttachmentsView.translatesAutoresizingMaskIntoConstraints = false

        topAttachmentsView.axis = .vertical
        topAttachmentsView.spacing = UIStackView.spacingUseSystem
        topAttachmentsView.layoutMargins = .init(top: 6, left: 0, bottom: 6, right: 0)
        topAttachmentsView.isLayoutMarginsRelativeArrangement = true
        topAttachmentsView.translatesAutoresizingMaskIntoConstraints = false

        bottomAttachmentsView.axis = .vertical
        bottomAttachmentsView.spacing = UIStackView.spacingUseSystem
        bottomAttachmentsView.layoutMargins = .init(top: 6, left: 0, bottom: 6, right: 0)
        bottomAttachmentsView.isLayoutMarginsRelativeArrangement = true
        bottomAttachmentsView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func addLayoutGuides() {
        attachmentLayoutView.translatesAutoresizingMaskIntoConstraints = false
        textInputView.addSubview(attachmentLayoutView)
        attachmentLayoutView.addLayoutGuide(attachmentLayoutGuide)
        attachmentLayoutView.addLayoutGuide(leadingColumnGuide)
        attachmentLayoutView.addLayoutGuide(editorColumnGuide)

        NSLayoutConstraint.activate([
            attachmentLayoutView.leadingAnchor.constraint(
                equalTo: textInputView.leadingAnchor
            ),
            attachmentLayoutView.topAnchor.constraint(
                equalTo: textInputView.topAnchor
            ),
            attachmentLayoutView.trailingAnchor.constraint(
                equalTo: textInputView.trailingAnchor
            ),
            attachmentLayoutView.bottomAnchor.constraint(
                equalTo: textInputView.bottomAnchor
            ),

            attachmentLayoutGuide.leadingAnchor.constraint(
                equalTo: attachmentLayoutView.leadingAnchor
            ),
            attachmentLayoutGuide.topAnchor.constraint(
                equalTo: attachmentLayoutView.topAnchor
            ),
            attachmentLayoutGuide.trailingAnchor.constraint(
                equalTo: attachmentLayoutView.trailingAnchor
            ),
            attachmentLayoutGuide.bottomAnchor.constraint(
                equalTo: attachmentLayoutView.bottomAnchor
            ),
        ])
    }

    private func addAttachmentViews() {
        // UITextView renders and scrolls its text through textInputView. Keep
        // the attachment canvas in that same view hierarchy so every slot
        // follows the text's content offset.
        attachmentLayoutView.addSubview(headerAttachmentsView)
        attachmentLayoutView.addSubview(leadingAttachmentsView)
        attachmentLayoutView.addSubview(topAttachmentsView)
        attachmentLayoutView.addSubview(bottomAttachmentsView)
    }

    private func activateLayoutConstraints() {
        NSLayoutConstraint.activate([
            headerAttachmentsView.topAnchor.constraint(
                equalTo: attachmentLayoutGuide.topAnchor
            ),
            headerAttachmentsView.leadingAnchor.constraint(
                equalTo: attachmentLayoutGuide.leadingAnchor
            ),
            headerAttachmentsView.trailingAnchor.constraint(
                equalTo: attachmentLayoutGuide.trailingAnchor
            ),

            leadingColumnGuide.leadingAnchor.constraint(
                equalTo: attachmentLayoutGuide.leadingAnchor
            ),
            emptyLeadingColumnWidthConstraint,
            leadingColumnGuide.topAnchor.constraint(
                equalTo: headerAttachmentsView.bottomAnchor
            ),
            leadingAttachmentsView.leadingAnchor.constraint(
                equalTo: leadingColumnGuide.leadingAnchor
            ),
            leadingAttachmentsView.topAnchor.constraint(
                equalTo: leadingColumnGuide.topAnchor
            ),
            leadingAttachmentsView.trailingAnchor.constraint(
                equalTo: leadingColumnGuide.trailingAnchor
            ),

            editorColumnGuide.leadingAnchor.constraint(
                equalTo: leadingColumnGuide.trailingAnchor
            ),
            editorColumnGuide.topAnchor.constraint(
                equalTo: headerAttachmentsView.bottomAnchor
            ),
            editorColumnGuide.trailingAnchor.constraint(
                equalTo: attachmentLayoutGuide.trailingAnchor
            ),
            editorColumnGuide.bottomAnchor.constraint(
                equalTo: attachmentLayoutGuide.bottomAnchor
            ),

            topAttachmentsView.topAnchor.constraint(
                equalTo: editorColumnGuide.topAnchor
            ),
            topAttachmentsView.leadingAnchor.constraint(
                equalTo: editorColumnGuide.leadingAnchor
            ),
            topAttachmentsView.trailingAnchor.constraint(
                equalTo: editorColumnGuide.trailingAnchor
            ),

            bottomAttachmentsView.bottomAnchor.constraint(
                equalTo: editorColumnGuide.bottomAnchor
            ),
            bottomAttachmentsView.leadingAnchor.constraint(
                equalTo: editorColumnGuide.leadingAnchor
            ),
            bottomAttachmentsView.trailingAnchor.constraint(
                equalTo: editorColumnGuide.trailingAnchor
            ),
        ])
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        updateTextContainerInsetIfNeeded()
    }

    private func updateTextContainerInsetIfNeeded() {
        guard !isUpdatingTextContainerInset else { return }

        attachmentLayoutView.layoutIfNeeded()
        let availableWidth = textInputView.bounds.width
        guard availableWidth > 0 else { return }

        let leadingWidth = fittingSize(for: leadingAttachmentsView).width
        let editorWidth = max(0, availableWidth - leadingWidth)
        let attachmentInsets = UIEdgeInsets(
            top: fittingHeight(for: headerAttachmentsView, width: availableWidth)
                + fittingHeight(for: topAttachmentsView, width: editorWidth),
            left: leadingWidth,
            bottom: fittingHeight(for: bottomAttachmentsView, width: editorWidth),
            right: textContainerInset.right
        )

        guard lastAppliedAttachmentInsets != attachmentInsets
            || textContainerInset != attachmentInsets
        else {
            return
        }

        isUpdatingTextContainerInset = true
        lastAppliedAttachmentInsets = attachmentInsets
        textContainerInset = attachmentInsets
        isUpdatingTextContainerInset = false
    }

    private func fittingSize(for view: UIView) -> CGSize {
        view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    private func fittingHeight(for view: UIView, width: CGFloat) -> CGFloat {
        view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }
}
