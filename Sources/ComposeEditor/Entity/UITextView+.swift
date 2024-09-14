import UIKit

extension UITextView {
    // selectしているRangeがいる行のRange
    var selectedLineTextRange: UITextRange? {
        guard let selectedTextRange else { return nil }
        let selectedLineTextRangeStart = tokenizer.position(
            from: selectedTextRange.start,
            toBoundary: .line,
            inDirection: .layout(.left)
        )
        let selectedLineTextRangeEnd = tokenizer.position(
            from: selectedTextRange.start,
            toBoundary: .line,
            inDirection: .layout(.right)
        )
        guard let selectedLineTextRangeStart, let selectedLineTextRangeEnd else { return nil }
        return textRange(from: selectedLineTextRangeStart, to: selectedLineTextRangeEnd)
    }
}

extension UITextView {
    func lineBackwardAttributedText(at position: UITextPosition) -> NSAttributedString? {
        guard let from = selectedLineTextRange?.start else { return nil }
        let to = position
        guard let textRange = textRange(from: from, to: to) else { return nil }
        return attributedText(in: textRange)
    }

    func lineForwardAttributedText(at position: UITextPosition) -> NSAttributedString? {
        let from = position
        guard let to = selectedLineTextRange?.end else { return nil }
        guard let textRange = textRange(from: from, to: to) else { return nil }
        return attributedText(in: textRange)
    }
    
    func backwardAttributedText(at position: UITextPosition) -> NSAttributedString? {
        let from = beginningOfDocument
        let to = position
        guard let textRange = textRange(from: from, to: to) else { return nil }
        return attributedText(in: textRange)
    }
    
    func forwardAttributedText(at position: UITextPosition) -> NSAttributedString? {
        let from = position
        let to = endOfDocument
        guard let textRange = textRange(from: from, to: to) else { return nil }
        return attributedText(in: textRange)
    }
}
