import ComposeEditor
import SwiftUI
import UIKit

@main
struct ExampleApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ExampleViewControllerRepresentable()
                .ignoresSafeArea()
        }
    }
}

private struct ExampleViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: ComposeViewController())
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {}
}

private final class ComposeViewController: UIViewController, UITextViewDelegate {
    private let textView = ComposeTextView()
    private let characterCountLabel = UILabel()

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
        updateCharacterCount()
    }
}
