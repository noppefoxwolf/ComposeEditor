import UIKit

open class AttachmentTextView: NativePlaceholderTextView {
    /// Horizontal bounds for an attachment slot. Neither option adds text padding.
    public enum AttachmentHorizontalLayout: Equatable {
        /// Stay inside the horizontal safe area (and the leading column for top/bottom slots).
        case safeArea
        /// Use the entire text input canvas, including the space beside the leading column.
        /// Use `.scrollableAxes` to keep that canvas as wide as the scroll view.
        case fullWidth
    }

    public var headerAttachmentsHorizontalLayout: AttachmentHorizontalLayout = .safeArea {
        didSet { setNeedsLayout() }
    }
    public var topAttachmentsHorizontalLayout: AttachmentHorizontalLayout = .safeArea {
        didSet { setNeedsLayout() }
    }
    public var bottomAttachmentsHorizontalLayout: AttachmentHorizontalLayout = .safeArea {
        didSet { setNeedsLayout() }
    }
    public var leadingAttachmentsHorizontalLayout: AttachmentHorizontalLayout = .safeArea {
        didSet { setNeedsLayout() }
    }

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
    private var horizontalConstraints: [NSLayoutConstraint] = []
    private var horizontalPolicies: [AttachmentHorizontalLayout] = []
    private lazy var safeAreaLeftConstraint = attachmentLayoutGuide.leftAnchor.constraint(
        equalTo: attachmentLayoutView.leftAnchor
    )
    private lazy var safeAreaRightConstraint = attachmentLayoutGuide.rightAnchor.constraint(
        equalTo: attachmentLayoutView.rightAnchor
    )

    /// Assigning this property sets the design padding, excluding attachments and safe area.
    /// Reading it includes attachment space and horizontal safe area missing from adjustedContentInset.
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
        for stack in [headerAttachmentsView, leadingAttachmentsView, topAttachmentsView, bottomAttachmentsView] {
            stack.axis = .vertical
            stack.spacing = UIStackView.spacingUseSystem
            stack.layoutMargins = .zero
            stack.insetsLayoutMarginsFromSafeArea = false
            stack.isLayoutMarginsRelativeArrangement = true
            stack.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func addLayoutGuides() {
        attachmentLayoutView.translatesAutoresizingMaskIntoConstraints = false
        textInputView.addSubview(attachmentLayoutView)
        attachmentLayoutView.addLayoutGuide(attachmentLayoutGuide)
        attachmentLayoutView.addLayoutGuide(leadingColumnGuide)
        attachmentLayoutView.addLayoutGuide(editorColumnGuide)

        NSLayoutConstraint.activate([
            safeAreaLeftConstraint,
            safeAreaRightConstraint,
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

            attachmentLayoutGuide.topAnchor.constraint(
                equalTo: attachmentLayoutView.topAnchor
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

            editorColumnGuide.leftAnchor.constraint(
                greaterThanOrEqualTo: attachmentLayoutGuide.leftAnchor
            ),
            editorColumnGuide.rightAnchor.constraint(
                lessThanOrEqualTo: attachmentLayoutGuide.rightAnchor
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

            bottomAttachmentsView.bottomAnchor.constraint(
                equalTo: editorColumnGuide.bottomAnchor
            ),
        ])
        let columnStart = editorColumnGuide.leadingAnchor.constraint(
            equalTo: leadingColumnGuide.trailingAnchor
        )
        // A full-width leading attachment may be narrower than the unsafe area.
        // In that case the required safe bounds take precedence over its edge.
        columnStart.priority = .init(999)
        columnStart.isActive = true
    }

    open override func layoutSubviews() {
        updateHorizontalLayoutIfNeeded()
        updateTextContainerInsetIfNeeded()
        super.layoutSubviews()
    }

    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    open override func adjustedContentInsetDidChange() {
        super.adjustedContentInsetDidChange()
        setNeedsLayout()
    }

    private func updateHorizontalLayoutIfNeeded() {
        // UITextView's internal text input view may keep a left-to-right semantic
        // direction even when the public text view is explicitly right-to-left.
        let direction: UISemanticContentAttribute = effectiveUserInterfaceLayoutDirection == .rightToLeft
            ? .forceRightToLeft : .forceLeftToRight
        if attachmentLayoutView.semanticContentAttribute != direction {
            attachmentLayoutView.semanticContentAttribute = direction
        }
        // UIKit already removes adjustedContentInset from textInputView's width.
        // Only supply the horizontal protection missing from that canvas. Leave
        // navigation bar and keyboard adjustment entirely to the scroll view.
        let left = max(0, safeAreaInsets.left - adjustedContentInset.left)
        let right = max(0, safeAreaInsets.right - adjustedContentInset.right)
        if safeAreaLeftConstraint.constant != left { safeAreaLeftConstraint.constant = left }
        if safeAreaRightConstraint.constant != -right { safeAreaRightConstraint.constant = -right }
        let policies = [
            headerAttachmentsHorizontalLayout, topAttachmentsHorizontalLayout,
            bottomAttachmentsHorizontalLayout, leadingAttachmentsHorizontalLayout,
        ]
        guard policies != horizontalPolicies else { return }
        horizontalPolicies = policies
        NSLayoutConstraint.deactivate(horizontalConstraints)
        horizontalConstraints = [
            leadingColumnGuide.leadingAnchor.constraint(
                equalTo: leadingAttachmentsHorizontalLayout == .safeArea
                    ? attachmentLayoutGuide.leadingAnchor : attachmentLayoutView.leadingAnchor
            ),
        ]
        for (slot, policy, guide) in [
            (headerAttachmentsView, headerAttachmentsHorizontalLayout, attachmentLayoutGuide),
            (topAttachmentsView, topAttachmentsHorizontalLayout, editorColumnGuide),
            (bottomAttachmentsView, bottomAttachmentsHorizontalLayout, editorColumnGuide),
        ] {
            horizontalConstraints += [
                slot.leadingAnchor.constraint(
                    equalTo: policy == .safeArea ? guide.leadingAnchor : attachmentLayoutView.leadingAnchor
                ),
                slot.trailingAnchor.constraint(
                    equalTo: policy == .safeArea ? guide.trailingAnchor : attachmentLayoutView.trailingAnchor
                ),
            ]
        }
        NSLayoutConstraint.activate(horizontalConstraints)
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
            left: baseTextContainerInset.left + editorColumnGuide.layoutFrame.minX,
            bottom: baseTextContainerInset.bottom + bottomAttachmentsView.bounds.height,
            right: baseTextContainerInset.right + attachmentLayoutView.bounds.width
                - editorColumnGuide.layoutFrame.maxX
        )
        guard textContainerInset != insets else { return }

        isUpdatingTextContainerInset = true
        textContainerInset = insets
        isUpdatingTextContainerInset = false
    }
}
