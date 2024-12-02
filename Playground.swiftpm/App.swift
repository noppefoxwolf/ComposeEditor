import SwiftUI
import ComposeEditor
import os

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        UINavigationController(rootViewController: ViewController())
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

final class ViewController: UIViewController, UITextViewDelegate {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier! + ".logger",
        category: #file
    )
    let textView = ComposeTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        textView.delegate = self
        textView.placeholder = "Hello, World"
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
        ])
        
        let attachmentView = _UIHostingView(rootView: Color.gray.frame(height: 44))
        textView.topAttachmentsView.addArrangedSubview(attachmentView)
        
        let attachmentView2 = _UIHostingView(rootView: Color.gray.frame(height: 44))
        textView.bottomAttachmentsView.addArrangedSubview(attachmentView2)
        
        let attachmentView3 = _UIHostingView(rootView: Color.gray.frame(width: 64, height: 34))
        textView.leadingAttachmentsView.addArrangedSubview(attachmentView3)
        
        navigationController?.setToolbarHidden(false, animated: false)
        
        setToolbarItems([
            UIBarButtonItem(
                image: UIImage(systemName: "text.insert"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.insertText("insert", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "text.append"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.appendText("append", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "text.append"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.appendText("@noppe #hashtag", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "text.append"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.appendText("https://example.com", addingWhitespaceIfNeeded: true)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "doc.on.clipboard.fill"),
                primaryAction: UIAction { [unowned self] _ in
                    textView.virtualKeyboard.replaceText("Paste")
                }
            ),
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
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        logger.debug("\(#function) \(textView.text) \(range) \(text)")
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        logger.debug("\(#function)")
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        logger.debug("\(#function)")
    }
}

