import SwiftUI
import ComposeEditor

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
        ViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

final class ViewController: UIViewController {
    let composeTextView = ComposeTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        composeTextView.placeholder = "Hello, World"
        view.addSubview(composeTextView)
        composeTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            composeTextView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: composeTextView.bottomAnchor),
            composeTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: composeTextView.trailingAnchor),
        ])
        
        let attachmentView = _UIHostingView(rootView: Color.green.frame(height: 44))
        composeTextView.bottomAttachmentsView.addArrangedSubview(attachmentView)
        
        let attachmentView2 = _UIHostingView(rootView: Color.red.frame(width: 64, height: 34))
        composeTextView.leadingAttachmentsView.addArrangedSubview(attachmentView2)
    }
}

