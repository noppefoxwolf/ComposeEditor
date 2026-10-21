import ComposeEditor
import ComposeEditorTokenBuiltins
import TokenTextView
import UIKit

final class ComposeViewController: UIViewController, UITextViewDelegate {
    private let textView = ComposeTextView()
    private let characterCountLabel = UILabel()
    private let shortcodeIdentifiers = ["fire", "heart", "star"]
    private let hashtags = ["swift", "ios", "mastodon", "ComposeEditor"]
    private let mentions = ["alice", "bob", "noppe", "noppe@mastodon.social"]
    private lazy var overflowMenuItem = UIBarButtonItem(
        title: nil,
        image: UIImage(systemName: "ellipsis.circle"),
        primaryAction: nil,
        menu: UIMenu(children: [
            UIAction(title: "Sample", image: UIImage(systemName: "text.insert")) { [weak self] _ in
                self?.insertExampleText()
            },
            UIAction(title: "Clear", image: UIImage(systemName: "trash")) { [weak self] _ in
                self?.clearText()
            },
            UIAction(title: "Done", image: UIImage(systemName: "keyboard.chevron.compact.down")) { [weak self] _ in
                self?.textView.resignFirstResponder()
            },
        ])
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "ComposeEditor"
        view.backgroundColor = .systemBackground

        configureTextView()
        configureAttachments()
        configureToolbar()
        insertExampleText()
    }

    private func configureTextView() {
        textView.delegate = self
        textView.register(HashtagTokenBehavior())
        textView.register(MastodonMentionTokenBehavior())
        textView.register(URLTokenBehavior())
        textView.register(ShortcodeTokenBehavior(
            maximumTokenLength: 16,
            attachmentProvider: { [weak self] match, font, attributes in
                self?.shortcodeAttachment(for: match, font: font, attributes: attributes)
            }
        ))
        textView.placeholder = "Write something…"
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .systemBackground
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true
        textView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
    }

    private func configureAttachments() {
        textView.headerAttachmentsView.addArrangedSubview(ReplyPreviewView())
        textView.leadingAttachmentsView.addArrangedSubview(ProfileView())
        textView.topAttachmentsView.addArrangedSubview(AudienceView())
        textView.bottomAttachmentsView.addArrangedSubview(LinkPreviewView())
    }

    private func updateSuggestions() {
        guard let context = textView.activeSuggestionContext else {
            setToolbarItems([
                .flexibleSpace(),
                UIBarButtonItem(customView: characterCountLabel),
                overflowMenuItem,
            ], animated: false)
            return
        }

        let candidates: [String]
        let marker: String
        switch context.behaviorIdentifier {
        case "shortcode":
            candidates = shortcodeIdentifiers
            marker = ":"
        case "hashtag":
            candidates = hashtags
            marker = "#"
        case "mastodon-mention":
            candidates = mentions
            marker = "@"
        default:
            setToolbarItems([
                .flexibleSpace(),
                UIBarButtonItem(customView: characterCountLabel),
                overflowMenuItem,
            ], animated: false)
            return
        }
        let prefix = context.prefix.lowercased()
        let suffix = context.suffix.lowercased()
        let matches = candidates.filter {
            let candidate = $0.lowercased()
            return candidate.hasPrefix(prefix) && (suffix.isEmpty || candidate.hasSuffix(suffix))
        }

        let suggestionItems = matches.prefix(3).map { candidate in
            let completeTitle = context.behaviorIdentifier == "shortcode"
                ? "\(marker)\(candidate)\(marker)"
                : "\(marker)\(candidate)"
            let title = completeTitle.count > 14
                ? String(completeTitle.prefix(12)) + "…"
                : completeTitle
            return UIBarButtonItem(
                title: title,
                image: nil,
                primaryAction: UIAction(title: completeTitle) { [weak self] _ in
                    self?.applySuggestion(candidate, behaviorIdentifier: context.behaviorIdentifier)
                },
                menu: nil
            )
        }
        setToolbarItems(suggestionItems + [
            .flexibleSpace(),
            UIBarButtonItem(customView: characterCountLabel),
            overflowMenuItem,
        ], animated: false)
    }

    private func applySuggestion(_ candidate: String, behaviorIdentifier: String) {
        guard let context = textView.activeSuggestionContext,
              context.behaviorIdentifier == behaviorIdentifier else {
            return
        }

        let replacement: String
        switch behaviorIdentifier {
        case "shortcode":
            replacement = ":\(candidate):"
        case "hashtag":
            replacement = "#\(candidate)"
        case "mastodon-mention":
            replacement = "@\(candidate)"
        default:
            return
        }
        textView.applySuggestion(replacement, for: context)
        updateSuggestions()
    }

    private func shortcodeAttachment(
        for match: TokenMatch,
        font: UIFont,
        attributes: [NSAttributedString.Key: Any]
    ) -> NSTextAttachment? {
        let symbols = [
            "fire": "flame.fill",
            "heart": "heart.fill",
            "star": "star.fill",
        ]
        guard let symbolName = symbols[match.identifier],
              let image = UIImage(
                systemName: symbolName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize)
              ) else {
            return nil
        }

        let color = attributes[.foregroundColor] as? UIColor ?? textView.tintColor ?? .label
        let attachment = NSTextAttachment()
        attachment.image = image.withTintColor(color, renderingMode: .alwaysOriginal)
        attachment.bounds = CGRect(
            x: 0,
            y: font.descender,
            width: image.size.width,
            height: image.size.height
        )
        return attachment
    }

    private func configureToolbar() {
        navigationController?.setToolbarHidden(false, animated: false)

        characterCountLabel.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
            weight: .regular
        )
        characterCountLabel.textColor = .secondaryLabel

        updateSuggestions()
    }

    private func insertExampleText() {
        textView.virtualKeyboard.replaceText(
            "This example keeps the attachment views inside the UITextView.\n\n"
                + "Try # or @ for hashtag and mention suggestions, or type : to choose a shortcode.\n\n"
                + "Use :star:, :heart:, and :fire: to insert inline symbol attachments.\n\n"
                + "The header, leading profile, audience control, and link preview are all supplied through the public attachment slots.\n\n"
                + String(
                    repeating: "Scroll to inspect how the text and attachments share the editor content. ",
                    count: 10
                )
        )
        updateCharacterCount()
    }

    private func clearText() {
        textView.text = ""
        updateCharacterCount()
        textView.becomeFirstResponder()
    }

    private func updateCharacterCount() {
        let remainingCount = 280 - (textView.text?.count ?? 0)
        characterCountLabel.text = remainingCount.formatted()
        characterCountLabel.textColor = remainingCount < 0 ? .systemRed : .secondaryLabel
    }

    func textViewDidChange(_ textView: UITextView) {
        (textView as? TokenTextView)?.handleTextViewDidChange(textView)
        updateSuggestions()
        updateCharacterCount()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        (textView as? TokenTextView)?.handleTextViewDidChangeSelection(textView)
        updateSuggestions()
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        (textView as? TokenTextView)?.shouldChangeText(in: range, replacementText: text) ?? true
    }
}
