import Combine
import UIKit

open class PlaceholderTextView: UITextView {

    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        return label
    }()

    public var placeholder: String? = nil {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    open override var text: String! {
        didSet {
            applyContentAvailable()
        }
    }

    open override var font: UIFont? {
        didSet { applyFont() }
    }

    open override var textContainerInset: UIEdgeInsets {
        didSet { applyInsets() }
    }

    private var topConstraint: NSLayoutConstraint? = nil
    private var leadingConstraint: NSLayoutConstraint? = nil

    private var cancellables: Set<AnyCancellable> = []

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        addSubview(placeholderLabel)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        leadingConstraint = placeholderLabel.leadingAnchor.constraint(
            equalTo: leadingAnchor
        )
        topConstraint = placeholderLabel.topAnchor.constraint(
            equalTo: topAnchor
        )
        NSLayoutConstraint.activate(
            [topConstraint, leadingConstraint].compactMap({ $0 })
        )

        NotificationCenter.default
            .publisher(
                for: UITextView.textDidChangeNotification,
                object: self
            )
            .compactMap({ $0.object as? UITextView })
            .map({ $0.text.isEmpty })
            .removeDuplicates()
            .sink { [unowned self] _ in
                applyContentAvailable()
            }
            .store(in: &cancellables)

        applyInsets()
    }

    open func isContentAvailable() -> Bool {
        !text.isEmpty
    }

    public func applyContentAvailable() {
        let isHidden = isContentAvailable()
        placeholderLabel.isHidden = isHidden
    }

    // https://github.com/Hoangtaiki/PlaceholderUITextView#some-notes
    private func applyInsets() {
        topConstraint?.constant = textContainerInset.top
        // TODO: observe lineFragmentPadding changes
        leadingConstraint?.constant = textContainerInset.left + textContainer.lineFragmentPadding
        setNeedsLayout()
    }

    func applyFont() {
        placeholderLabel.font = font
    }
}
