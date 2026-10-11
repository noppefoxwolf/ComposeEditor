# ComposeEditor

ComposeEditor is a UIKit text editor for compose screens. It combines a TextKit 2 text view with placeholder support, attachment slots around the editable text, virtual keyboard helpers, pasteboard hooks, and optional token matching.

## Features

- `ComposeTextView`, a ready-to-use compose view that inherits the token editing APIs.
- `TokenTextView`, a standalone TextKit 2 text view for registering token behaviors.
- Built-in hashtag, Mastodon mention, and shortcode behaviors in an optional product.
- Inline `NSTextAttachment` replacement for matched tokens, with literal text restored when an attachment is edited or removed.
- Placeholder text and header, top, bottom, and leading attachment slots that scroll with the editor.
- Helpers for inserting, appending, replacing, and deleting text through the text view.
- Custom copy, cut, and paste actions with completion callbacks.

## Requirements

- iOS 17 or later
- Swift 6.4 or later
- TextKit 2

`TokenTextView` requires TextKit 2 and checks for it when initialized.

## Products

| Product | Contents |
| --- | --- |
| `ComposeEditor` | `ComposeTextView`, a small facade over `TokenTextView` with the compose editor APIs inherited from its base classes. |
| `TokenTextView` | Token detection, styling, suggestions, and attachment replacement for a TextKit 2 text view. |
| `ComposeEditorTokenBuiltins` | Hashtag, Mastodon mention, and shortcode behaviors. |

The underlying `TextEditor` target is an implementation dependency. Add the `ComposeEditor` product or `TokenTextView` product to use the editor; add `ComposeEditorTokenBuiltins` only if you want its built-in behaviors.

## Installation

In Xcode, add this repository as a Swift Package dependency and select the products your app uses. In `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/noppefoxwolf/ComposeEditor.git",
        from: "0.1.1"
    )
]
```

Add the products to your target:

```swift
dependencies: [
    .product(name: "ComposeEditor", package: "ComposeEditor"),
    .product(name: "TokenTextView", package: "ComposeEditor"),
    .product(name: "ComposeEditorTokenBuiltins", package: "ComposeEditor"),
]
```

If you only need the token editor, use `TokenTextView` without `ComposeEditor`. If you implement every behavior yourself, you can omit `ComposeEditorTokenBuiltins`.

## Getting started

Create and configure a compose editor from your view controller:

```swift
import ComposeEditor
import UIKit

let textView = ComposeTextView()
textView.placeholder = "What's happening?"
textView.font = .preferredFont(forTextStyle: .body)
textView.adjustsFontForContentSizeCategory = true
```

`ComposeTextView` is a `TokenTextView`, so it also supports token registration. To use the built-in behaviors, add the `TokenTextView` and `ComposeEditorTokenBuiltins` products and import their modules:

```swift
import ComposeEditor
import ComposeEditorTokenBuiltins
import TokenTextView
import UIKit

let textView = ComposeTextView()
textView.register(HashtagTokenBehavior())
textView.register(MastodonMentionTokenBehavior())
```

Hashtags and Mastodon mentions are styled with the text view's tint color. The hashtag behavior recognizes Unicode letters and numbers. The mention behavior recognizes local `@user` names and federated `@user@host.example` names.

## Forward text view delegate callbacks

The app remains the `UITextViewDelegate`. Forward the three callbacks below to let `TokenTextView` track edits, update token styling, and replace completed tokens. Return the result of `shouldChangeText(in:replacementText:)` from the matching delegate callback.

```swift
func textViewDidChange(_ textView: UITextView) {
    (textView as? TokenTextView)?.handleTextViewDidChange(textView)
}

func textViewDidChangeSelection(_ textView: UITextView) {
    (textView as? TokenTextView)?.handleTextViewDidChangeSelection(textView)
}

func textView(
    _ textView: UITextView,
    shouldChangeTextIn range: NSRange,
    replacementText text: String
) -> Bool {
    (textView as? TokenTextView)?.shouldChangeText(in: range, replacementText: text) ?? true
}
```

The editor delays matching while the system keyboard has marked text, then rescans when that composition ends. For token-related notifications, set `textView.tokenDelegate` to an object conforming to `TokenTextViewDelegate`. Its methods can observe editing-state changes and text changes with the changed range; both methods have default empty implementations.

## Read the active suggestion context

Built-in behaviors identify a partial token around a collapsed caret. Read `activeSuggestionContext` when the selection changes or the text changes:

```swift
if let context = textView.activeSuggestionContext {
    print(context.behaviorIdentifier) // for example, "hashtag"
    print(context.prefix)             // text before the caret in the token
    print(context.suffix)             // text after the caret in the token
    print(context.tokenRange)          // full token range in UTF-16 offsets
}
```

The context includes the behavior identifier, current text, selection, token range, and the prefix and suffix around the caret. It is `nil` when there is a selection, marked text, or no registered behavior that recognizes the caret context. Use the context to drive your own search or suggestion UI; ComposeEditor does not provide a suggestion list.

Apply a selected suggestion with the context used to produce it:

```swift
guard let context = textView.activeSuggestionContext else { return }
textView.applySuggestion(":fire:", for: context)
```

The editor replaces the full token range through the text view's normal editing pipeline. If the context is stale because the text or selection changed, the suggestion is ignored.

## Replace shortcodes with attachments

`ShortcodeTokenBehavior` recognizes standalone `:name:` tokens and asks your provider to create an `NSTextAttachment`. Supply the artwork and supported identifiers for your app:

```swift
let shortcodeSymbols = [
    "fire": "flame.fill",
    "heart": "heart.fill",
    "star": "star.fill",
]

let shortcodeBehavior = ShortcodeTokenBehavior(
    maximumTokenLength: 32
) { match, font, attributes in
    guard let symbolName = shortcodeSymbols[match.identifier],
          let image = UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize)
          ) else {
        return nil
    }

    let color = attributes[.foregroundColor] as? UIColor ?? .label
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

textView.register(shortcodeBehavior)
```

The complete token must be separated from neighboring text by whitespace or a text boundary. Returning `nil` from the provider leaves a match as editable text, so the provider can decide which names your app supports. The Playground includes a working SF Symbols attachment example.

When you need custom matching or styling, implement `TokenBehavior` with a `TokenDetector`, then optionally provide `TokenMatchAttributes` or `TokenAttachmentReplacement`. `TokenDetector.maximumTokenLength` bounds incremental scans, and its optional suggestion search can return the partial token context at the caret.

## Add views around the text

`ComposeTextView` exposes four `UIStackView` attachment slots:

```swift
textView.headerAttachmentsView.addArrangedSubview(headerView)
textView.topAttachmentsView.addArrangedSubview(audienceView)
textView.leadingAttachmentsView.addArrangedSubview(profileView)
textView.bottomAttachmentsView.addArrangedSubview(footerView)
```

The slots live in the text view's scrolling content. Use Auto Layout inside each arranged view to size its content. The Playground demonstrates all four positions.

## Use the virtual keyboard helper

`textView.virtualKeyboard` provides text operations that go through the text view's delegate:

```swift
textView.virtualKeyboard.insertText("Hello")
textView.virtualKeyboard.appendText(" #Swift", addingWhitespaceIfNeeded: true)
textView.virtualKeyboard.replaceText("Replacement text")
textView.virtualKeyboard.deleteBackward()
textView.virtualKeyboard.selectEndOfContent()
```

It is useful for compose controls that insert text into the editor. `addingWhitespaceIfNeeded` adds a separating space where needed when inserting or replacing text.

## Customize pasteboard actions

Set an action to replace the default copy, cut, or paste behavior, and use the corresponding callback to observe completion:

```swift
textView.copyAction = { textView in
    // Provide custom copy behavior.
}
textView.onCopy = { textView in
    // Update app state after copy.
}
```

The same pattern is available through `cutAction`/`onCut` and `pasteAction`/`onPaste`. Without a custom action, the text view uses UIKit's default operation. `TokenTextView` also copies marked token attachments as their original literal text.

## Playground

Open `Playground.swiftpm` in Xcode to explore the attachment slots, placeholder, character counter, token styling, shortcode suggestions, and inline shortcode attachments.

## License

ComposeEditor is released under the [MIT License](LICENSE).
