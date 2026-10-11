import RegexBuilder
import UIKit

extension UITextView {
    func hasLeftPadding(at position: UITextPosition) -> Bool {
        guard let backwardText = lineBackwardAttributedText(at: position)?.string else { return false }
        guard !backwardText.isEmpty else { return true }
        let regex = Regex {
            ZeroOrMore { .any }
            OneOrMore { .whitespace }
        }
        return backwardText.wholeMatch(of: regex) != nil
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
