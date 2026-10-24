import Foundation
import RegexBuilder
import UIKit

@MainActor
public final class VirtualKeyboard {
    weak var textView: UITextView? = nil
    let whiteSpace = " "

    public func insertText(_ text: String, smartInsert: Bool = false) {
        guard let textView,
              let range = textView.selectedTextRange,
              let replacement = approvedReplacement(text, in: range, smartInsert: smartInsert) else { return }
        textView.insertText(replacement)
    }

    public func appendText(_ text: String, smartInsert: Bool = false) {
        guard let textView else { return }
        let beforeSelectedRange = textView.selectedTextRange
        textView.selectedTextRange = textView.textRange(
            from: textView.endOfDocument,
            to: textView.endOfDocument
        )
        insertText(text, smartInsert: smartInsert)
        textView.selectedTextRange = beforeSelectedRange
    }

    public func replaceText(_ text: String, smartInsert: Bool = false) {
        guard let textView else { return }
        replaceText(textView.documentRange, withText: text, smartInsert: smartInsert)
    }

    public func replaceText(
        _ range: Range<String.Index>,
        withText text: String,
        smartInsert: Bool = false
    ) {
        guard let textView else { return }
        let textRange = textView.textRange(of: range, in: textView.text)
        guard let textRange else { return }
        replaceText(textRange, withText: text, smartInsert: smartInsert)
    }

    public func replaceText(
        _ textRange: UITextRange,
        withText text: String,
        smartInsert: Bool = false
    ) {
        guard let textView,
              let replacement = approvedReplacement(text, in: textRange, smartInsert: smartInsert) else { return }
        textView.replace(textRange, withText: replacement)
    }

    private func approvedReplacement(_ text: String, in textRange: UITextRange, smartInsert: Bool) -> String? {
        guard let textView else { return nil }
        var replacement = text
        if smartInsert {
            if !textView.hasLeftPadding(at: textRange.start) && !replacement.hasPrefix(whiteSpace) {
                replacement.insert(contentsOf: whiteSpace, at: replacement.startIndex)
            }
            if !textView.hasRightPadding(at: textRange.end) && !replacement.hasSuffix(whiteSpace) {
                replacement.append(contentsOf: whiteSpace)
            }
        }
        let range = NSRange(
            location: textView.offset(from: textView.beginningOfDocument, to: textRange.start),
            length: textView.offset(from: textRange.start, to: textRange.end)
        )
        let shouldChange = textView.delegate?.textView?(
            textView,
            shouldChangeTextIn: range,
            replacementText: replacement
        ) ?? true
        return shouldChange ? replacement : nil
    }

    public func deleteBackward() {
        textView?.deleteBackward()
    }

    public func selectEndOfContent() {
        guard let textView else { return }
        let regex = Regex {
            Repeat(1...) {
                ZeroOrMore {
                    CharacterClass.whitespace
                }
                ChoiceOf {
                    Regex.hashtag
                    One(.url())
                }
            }
        }
        let textRange: UITextRange?

        let text = textView.text!
        if let match = text.matches(of: regex).last {
            let offset = match.range.lowerBound.utf16Offset(in: text)
            let position = textView.position(
                from: textView.beginningOfDocument,
                offset: offset
            ) ?? textView.endOfDocument
            textRange = textView.textRange(from: position, to: position)
        } else {
            textRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        }
        textView.selectedTextRange = textRange
    }
}
