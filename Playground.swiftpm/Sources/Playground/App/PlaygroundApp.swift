import ComposeEditor
import SwiftUI
import UIKit

@main
struct PlaygroundApp: SwiftUI.App {
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
