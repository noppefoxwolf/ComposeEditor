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
    private var baseTextContainerInset = UIEdgeInsets.zero

    /// Assigning this property sets the text padding, excluding attachment space.
    /// Reading it returns the effective padding, including attachment space.
    open override var textContainerInset: UIEdgeInsets {
        didSet {
            guard !isUpdatingTextContainerInset else { return }
            baseTextContainerInset = textContainerInset
            setNeedsLayout()
        }
    }
    private lazy var emptyLeadingColumnWidthConstraint: NSLayoutConstraint = {
        let constraint = leadingColumnGuide.widthAnchor.constraint(equalToConstant: 0)
        constraint.priority = .fittingSizeLevel
        return constraint
    }()

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        baseTextContainerInset = textContainerInset
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
        headerAttachmentsView.layoutMargins = .zero
        headerAttachmentsView.isLayoutMarginsRelativeArrangement = true
        headerAttachmentsView.translatesAutoresizingMaskIntoConstraints = false

        leadingAttachmentsView.axis = .vertical
        leadingAttachmentsView.spacing = UIStackView.spacingUseSystem
        leadingAttachmentsView.layoutMargins = .zero
        leadingAttachmentsView.isLayoutMarginsRelativeArrangement = true
        leadingAttachmentsView.translatesAutoresizingMaskIntoConstraints = false

        topAttachmentsView.axis = .vertical
        topAttachmentsView.spacing = UIStackView.spacingUseSystem
        topAttachmentsView.layoutMargins = .zero
        topAttachmentsView.isLayoutMarginsRelativeArrangement = true
        topAttachmentsView.translatesAutoresizingMaskIntoConstraints = false

        bottomAttachmentsView.axis = .vertical
        bottomAttachmentsView.spacing = UIStackView.spacingUseSystem
        bottomAttachmentsView.layoutMargins = .zero
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
        updateTextContainerInsetIfNeeded()
        super.layoutSubviews()
    }

    private func updateTextContainerInsetIfNeeded() {
        guard !isUpdatingTextContainerInset else { return }

        // Reuse Auto Layout's resolved geometry instead of running four
        // independent fitting passes on every scroll or text layout.
        attachmentLayoutView.layoutIfNeeded()
        guard attachmentLayoutView.bounds.width > 0 else { return }

        let insets = UIEdgeInsets(
            top: baseTextContainerInset.top + headerAttachmentsView.bounds.height
                + topAttachmentsView.bounds.height,
            left: baseTextContainerInset.left + leadingAttachmentsView.bounds.width,
            bottom: baseTextContainerInset.bottom + bottomAttachmentsView.bounds.height,
            right: baseTextContainerInset.right
        )
        guard textContainerInset != insets else { return }

        isUpdatingTextContainerInset = true
        textContainerInset = insets
        isUpdatingTextContainerInset = false
    }
}
