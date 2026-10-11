# ComposeEditor

ComposeEditor is a UIKit text editor for compose screens. It provides attachment slots around the text, placeholder support, virtual keyboard helpers, pasteboard hooks, and registered token behaviors for styling or replacing text with attachments.

# Requirements

- Swift 6.4

- iOS 17

# Installation

[Adding Package Dependencies to Your App](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)

# Getting Started

```
let textView = ComposeTextView()
textView.placeholder = "What's happened?"
textView.bottomAttachmentsView.addArrangedSubView(footer)
textView.leadingAttachmentsView.addArrangedSubView(button)
textView.onCopy = { _ in }
```

`ComposeTextView` is a `TokenTextView`, so token behaviors can be registered directly. The host remains the `UITextViewDelegate` and must forward the three editing callbacks:

```swift
textView.register(HashtagTokenBehavior())
textView.register(MastodonMentionTokenBehavior())

func textViewDidChange(_ textView: UITextView) {
    (textView as? TokenTextView)?.handleTextViewDidChange(textView)
}

func textViewDidChangeSelection(_ textView: UITextView) {
    (textView as? TokenTextView)?.handleTextViewDidChangeSelection(textView)
}

func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    (textView as? TokenTextView)?.shouldChangeText(in: range, replacementText: text) ?? true
}
```

`TokenTextView` is also available as a separate product. Add the `ComposeEditorTokenBuiltins` product for the built-in hashtag, Mastodon mention, and shortcode behaviors. Custom `TokenBehavior` implementations only require `TokenTextView` (or the `ComposeEditor` façade).

# Maintainer

[@noppefoxwolf](https://twitter.com/noppefoxwolf)

# License

ComposeEditor is available under the MIT license. See the LICENSE file for more info.
