import Testing
import UIKit
import ComposeEditor

@Suite
@MainActor
struct VirtualKeyboardEditingTests {
    private final class RecordingDelegate: NSObject, UITextViewDelegate {
        var changes: [(NSRange, String)] = []
        var allowsChanges = true
        var changeNotifications = 0

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            changes.append((range, text))
            return allowsChanges
        }

        func textViewDidChange(_ textView: UITextView) {
            changeNotifications += 1
        }
    }

    @Test(arguments: [false, true])
    func insertionReportsTheSelectedUTF16Range(replacesSelection: Bool) {
        let textView = ComposeTextView()
        textView.text = "😀abc!"
        let selection = NSRange(location: 2, length: replacesSelection ? 3 : 0)
        textView.selectedRange = selection
        let delegate = RecordingDelegate()
        textView.delegate = delegate

        textView.virtualKeyboard.insertText("👩🏽‍💻")

        #expect(delegate.changes.count == 1)
        #expect(delegate.changes.first?.0 == selection)
        #expect(delegate.changes.first?.1 == "👩🏽‍💻")
        #expect(delegate.changeNotifications == 1)
        #expect(textView.text == (replacesSelection ? "😀👩🏽‍💻!" : "😀👩🏽‍💻abc!"))
    }

    @Test(arguments: [false, true], [false, true])
    func replacementReportsItsRangeAndFinalPaddedText(usesInsertion: Bool, allowsChanges: Bool) throws {
        let textView = ComposeTextView()
        textView.text = "😀abc!"
        let selection = NSRange(location: 2, length: 3)
        textView.selectedRange = selection
        let range = try #require(textView.selectedTextRange)
        let delegate = RecordingDelegate()
        delegate.allowsChanges = allowsChanges
        textView.delegate = delegate

        if usesInsertion {
            textView.virtualKeyboard.insertText("x", smartInsert: true)
        } else {
            textView.virtualKeyboard.replaceText(range, withText: "x", smartInsert: true)
        }

        #expect(delegate.changes.count == 1)
        #expect(delegate.changes.first?.0 == selection)
        #expect(delegate.changes.first?.1 == " x ")
        #expect(delegate.changeNotifications == (allowsChanges ? 1 : 0))
        #expect(textView.text == (allowsChanges ? "😀 x !" : "😀abc!"))
        if !allowsChanges {
            #expect(textView.selectedRange == selection)
        }
    }
}
