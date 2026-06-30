import SwiftUI
import ComposeEditor
import os

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
        }
    }
}

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: ViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

final class ViewController: UIViewController, UITextViewDelegate {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier! + ".logger",
        category: #file
    )

    private let textView = ComposeTextView()
    private let characterCountLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Compose"
        view.backgroundColor = .systemBackground
        configureTextView()
        configureAttachments()
        configureToolbar()
        updateCharacterCount()
    }

    private func configureTextView() {
        textView.delegate = self
        textView.placeholder = "What's happening?"
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .systemBackground
        textView.textContainerInset.left = 0

        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func configureAttachments() {
        textView.headerAttachmentsView.addArrangedSubview(ReplyPreviewView())
        textView.leadingAttachmentsView.addArrangedSubview(AvatarView())
        textView.topAttachmentsView.addArrangedSubview(VisibilityView())
        textView.bottomAttachmentsView.addArrangedSubview(LinkPreviewView())
    }

    private func configureToolbar() {
        navigationController?.setToolbarHidden(false, animated: false)

        setToolbarItems([
            UIBarButtonItem(
                image: UIImage(systemName: "photo"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.insertText("https://example.com/photo.jpg", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "at"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.insertText("@noppe", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "number"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.insertText("#ComposeEditor", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(customView: characterCountLabel),
            UIBarButtonItem(
                title: "Post",
                primaryAction: UIAction { [unowned self] _ in
                    post()
                }
            ),
            UIBarButtonItem.fixedSpace(12),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.forward.to.line"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.selectEndOfContent()
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.uturn.backward.circle"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.undoManager?.undo()
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.uturn.forward.circle"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.undoManager?.redo()
                }
            ),
        ], animated: false)
    }

    private func post() {
        logger.debug("Post: \(self.textView.text ?? "")")
        textView.resignFirstResponder()
    }

    private func updateCharacterCount() {
        let remainingCount = 280 - (textView.text?.count ?? 0)
        characterCountLabel.text = "\(remainingCount)"
        characterCountLabel.textColor = remainingCount < 0 ? .systemRed : .secondaryLabel
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        logger.debug("\(#function) \(textView.text ?? "") \(range) \(text)")
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        updateCharacterCount()
    }
}

private final class ReplyPreviewView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let replyIcon = UIImageView(image: UIImage(systemName: "arrowshape.turn.up.left.fill"))
        replyIcon.tintColor = .secondaryLabel
        replyIcon.contentMode = .scaleAspectFit
        replyIcon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Replying to @alice"
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "ComposeEditor makes UIKit text views easier to extend."
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2

        let stack = UIStackView(arrangedSubviews: [replyIcon, labelsStack])
        stack.alignment = .top
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            replyIcon.widthAnchor.constraint(equalToConstant: 20),
            replyIcon.heightAnchor.constraint(equalToConstant: 20),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class VisibilityView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.tinted()
        configuration.image = UIImage(systemName: "globe")
        configuration.title = "Public"
        configuration.imagePadding = 6
        configuration.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
        button.configuration = configuration

        let stack = UIStackView(arrangedSubviews: [button, UIView()])
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class AvatarView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class LinkPreviewView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let thumbnailView = UIImageView(image: UIImage(systemName: "doc.text.image"))
        thumbnailView.tintColor = .white
        thumbnailView.backgroundColor = .systemIndigo
        thumbnailView.contentMode = .center
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "ComposeEditor"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        let descriptionLabel = UILabel()
        descriptionLabel.text = "A UIKit text editor for rich compose screens."
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2

        let urlLabel = UILabel()
        urlLabel.text = "github.com/noppefoxwolf/ComposeEditor"
        urlLabel.font = .preferredFont(forTextStyle: .caption1)
        urlLabel.textColor = .tertiaryLabel

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, urlLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 3

        let stack = UIStackView(arrangedSubviews: [thumbnailView, labelsStack])
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalToConstant: 72),
            thumbnailView.heightAnchor.constraint(equalToConstant: 72),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
