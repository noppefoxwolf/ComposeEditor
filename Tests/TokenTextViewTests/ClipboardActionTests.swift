import Testing
import UIKit
import TextEditor
@testable import TokenTextView

@Suite
@MainActor
struct ClipboardActionTests {
    enum Action: CaseIterable {
        case copy, cut, paste

        func perform(on textView: UITextView) {
            switch self {
            case .copy: textView.copy(nil)
            case .cut: textView.cut(nil)
            case .paste: textView.paste(nil)
            }
        }
    }

    @Test(arguments: Action.allCases, [false, true])
    func customActionRunsBeforeExactlyOneCompletion(action: Action, usesTokens: Bool) {
        let textView: PasteboardActionTextView = usesTokens
            ? TokenTextView(frame: .zero, textContainer: nil)
            : PasteboardActionTextView(frame: .zero, textContainer: nil)
        textView.text = "unchanged"
        textView.selectedRange = NSRange(location: 0, length: textView.text.utf16.count)
        var events: [String] = []
        textView.copyAction = { _ in events.append("custom") }
        textView.cutAction = { _ in events.append("custom") }
        textView.pasteAction = { _ in events.append("custom") }
        textView.onCopy = { _ in events.append("completed") }
        textView.onCut = { _ in events.append("completed") }
        textView.onPaste = { _ in events.append("completed") }

        action.perform(on: textView)

        #expect(events == ["custom", "completed"])
        #expect(textView.text == "unchanged")
    }

    @Test(arguments: Action.allCases)
    func tokenClipboardActionCompletesAfterItsEffect(action: Action) {
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        let pasteboard = UIPasteboard.withUniqueName()
        defer { UIPasteboard.remove(withName: pasteboard.name) }
        textView.pasteboard = pasteboard
        pasteboard.string = "pasted"
        let source = NSMutableAttributedString(string: "A ")
        let attachment = NSMutableAttributedString(attachment: NSTextAttachment())
        attachment.addAttributes([
            .markedTextLiteral: ":star:",
            .markedTextBehavior: "shortcode",
        ], range: NSRange(location: 0, length: attachment.length))
        source.append(attachment)
        textView.attributedText = source
        textView.selectedRange = NSRange(location: 0, length: source.length)
        var completionCount = 0
        let completion: (UITextView) -> Void = { view in
            completionCount += 1
            switch action {
            case .copy:
                #expect(view.text == source.string)
                #expect(pasteboard.string == "A :star:")
            case .cut:
                #expect(view.text.isEmpty)
                #expect(pasteboard.string == "A :star:")
            case .paste:
                #expect(view.text == "pasted")
            }
        }
        textView.onCopy = completion
        textView.onCut = completion
        textView.onPaste = completion

        action.perform(on: textView)

        #expect(completionCount == 1)
    }
}
