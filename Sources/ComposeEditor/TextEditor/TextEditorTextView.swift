import UIKit
import RegexBuilder
import Foundation

open class TextEditorTextView: PasteboardActionTextView {
    public lazy var virtualKeyboard: VirtualKeyboard = {
        let virtualKeyboard = VirtualKeyboard()
        virtualKeyboard.textView = self
        return virtualKeyboard
    }()
}

@MainActor
public final class VirtualKeyboard {
    weak var textView: UITextView? = nil
    let whiteSpace = " "
    
    public func insertText(_ text: String, addingWhitespaceIfNeeded: Bool = false) {
        guard let textView else { return }
        guard let selectedTextRange = textView.selectedTextRange else { return }
        let location = textView.selectedRange.location
        let length = text.count
        let range = NSRange(location: location, length: length)
        let shouldChange = textView.delegate?.textView?(
            textView,
            shouldChangeTextIn: range,
            replacementText: text
        )
        if shouldChange ?? true {
            var text = text
            if addingWhitespaceIfNeeded {
                if !textView.hasLeftPadding(at: selectedTextRange.start) && !text.hasPrefix(whiteSpace) {
                    text.insert(contentsOf: whiteSpace, at: text.startIndex)
                }
                if !textView.hasRightPadding(at: selectedTextRange.end) && !text.hasSuffix(whiteSpace) {
                    text.append(contentsOf: whiteSpace)
                }
            }
            textView.insertText(text)
            textView.delegate?.textViewDidChange?(textView)
        }
    }
    
    public func appendText(_ text: String, addingWhitespaceIfNeeded: Bool = false) {
        guard let textView else { return }
        let beforeSelectedRange = textView.selectedTextRange
        textView.selectedTextRange = textView.textRange(
            from: textView.endOfDocument,
            to: textView.endOfDocument
        )
        insertText(text, addingWhitespaceIfNeeded: addingWhitespaceIfNeeded)
        textView.selectedTextRange = beforeSelectedRange
    }
    
    public func replaceText(_ text: String, addingWhitespaceIfNeeded: Bool = false) {
        guard let textView else { return }
        replaceText(textView.documentRange, withText: text, addingWhitespaceIfNeeded: addingWhitespaceIfNeeded)
    }
    
    public func replaceText(_ range: Range<String.Index>, withText text: String, addingWhitespaceIfNeeded: Bool = false) {
        guard let textView else { return }
        let textRange = textView.textRange(of: range, in: textView.text)
        guard let textRange else { return }
        replaceText(textRange, withText: text, addingWhitespaceIfNeeded: addingWhitespaceIfNeeded)
    }
    
    public func replaceText(_ textRange: UITextRange, withText text: String, addingWhitespaceIfNeeded: Bool = false) {
        guard let textView else { return }
        let startOffset = textView.offset(from: textRange.start, to: textRange.start)
        let endOffset = textView.offset(from: textRange.end, to: textRange.end)
        let range = NSRange(location: startOffset, length: endOffset - startOffset)
        let shouldChange = textView.delegate?.textView?(
            textView,
            shouldChangeTextIn: range,
            replacementText: text
        )
        if shouldChange ?? true {
            var text = text
            if addingWhitespaceIfNeeded {
                if !textView.hasLeftPadding(at: textRange.start) && !text.hasPrefix(whiteSpace) {
                    text.insert(contentsOf: whiteSpace, at: text.startIndex)
                }
                if !textView.hasRightPadding(at: textRange.end) && !text.hasSuffix(whiteSpace) {
                    text.append(contentsOf: whiteSpace)
                }
            }
            textView.replace(textRange, withText: text)
            textView.delegate?.textViewDidChange?(textView)
        }
    }
    
    public func deleteBackward() {
        guard let textView else { return }
        textView.deleteBackward()
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
                    Regex.mention
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

extension UITextView {
    func hasLeftPadding(at position: UITextPosition) -> Bool {
        guard let backwardText = lineBackwardAttributedText(at: position)?.string else { return false }
        guard !backwardText.isEmpty else { return true }
        let regex = Regex {
            ZeroOrMore { .any }
            OneOrMore { .whitespace }
        }
        let match = backwardText.wholeMatch(of: regex)
        return match != nil
    }
    
    func hasRightPadding(at position: UITextPosition) -> Bool {
        guard let forwardText = lineForwardAttributedText(at: position)?.string else { return false }
        guard !forwardText.isEmpty else { return true }
        let regex = Regex {
            OneOrMore { .whitespace }
            ZeroOrMore { .any }
        }
        return forwardText.wholeMatch(of: regex) != nil
    }
}
