import ComposeEditor
import ComposeEditorTokenBuiltins
import TokenTextView
import UIKit

final class ComposeViewController: UIViewController, UITextViewDelegate {
    private let textView = ComposeTextView()
    private let characterCountLabel = UILabel()
    private let shortcodeSuggestionsView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.isHidden = true
        return stackView
    }()
    private let shortcodeIdentifiers = ["fire", "heart", "star"]

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
        textView.topAttachmentsView.addArrangedSubview(shortcodeSuggestionsView)
        textView.topAttachmentsView.addArrangedSubview(AudienceView())
        textView.bottomAttachmentsView.addArrangedSubview(LinkPreviewView())
    }

    private func updateShortcodeSuggestions() {
        guard let context = textView.activeSuggestionContext,
              context.behaviorIdentifier == "shortcode" else {
            shortcodeSuggestionsView.isHidden = true
            return
        }

        let prefix = context.prefix.lowercased()
        let suffix = context.suffix.lowercased()
        let matches = shortcodeIdentifiers.filter {
            $0.hasPrefix(prefix) && (suffix.isEmpty || $0.hasSuffix(suffix))
        }

        shortcodeSuggestionsView.arrangedSubviews.forEach { view in
            shortcodeSuggestionsView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for identifier in matches {
            var configuration = UIButton.Configuration.tinted()
            configuration.title = ":\(identifier):"
            configuration.buttonSize = .small
            configuration.cornerStyle = .capsule

            let button = UIButton(configuration: configuration)
            button.accessibilityHint = "Insert shortcode"
            button.addAction(UIAction { [weak self] _ in
                self?.applyShortcodeSuggestion(identifier)
            }, for: .touchUpInside)
            shortcodeSuggestionsView.addArrangedSubview(button)
        }
        shortcodeSuggestionsView.isHidden = matches.isEmpty
    }

    private func applyShortcodeSuggestion(_ identifier: String) {
        guard let context = textView.activeSuggestionContext,
              context.behaviorIdentifier == "shortcode" else {
            return
        }

        textView.applySuggestion(":\(identifier):", for: context)
        updateShortcodeSuggestions()
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

        setToolbarItems([
            UIBarButtonItem(
                title: "Sample",
                primaryAction: UIAction { [weak self] _ in
                    self?.insertExampleText()
                }
            ),
            UIBarButtonItem(
                title: "Clear",
                primaryAction: UIAction { [weak self] _ in
                    self?.clearText()
                }
            ),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(customView: characterCountLabel),
            UIBarButtonItem(
                title: "Done",
                primaryAction: UIAction { [weak self] _ in
                    self?.textView.resignFirstResponder()
                }
            ),
        ], animated: false)
    }

    private func insertExampleText() {
        textView.virtualKeyboard.replaceText(
            "This example keeps the attachment views inside the UITextView.\n\n"
                + "Type : to choose a shortcode, or use :star:, :heart:, and :fire: to insert inline symbol attachments.\n\n"
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
        updateShortcodeSuggestions()
        updateCharacterCount()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        (textView as? TokenTextView)?.handleTextViewDidChangeSelection(textView)
        updateShortcodeSuggestions()
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        (textView as? TokenTextView)?.shouldChangeText(in: range, replacementText: text) ?? true
    }
}
