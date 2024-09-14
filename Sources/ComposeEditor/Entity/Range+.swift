import UIKit

extension UITextView {
    func textRange(of range: Range<String.Index>, in text: String) -> UITextRange? {
        let from = position(
            from: beginningOfDocument,
            offset: range.lowerBound.utf16Offset(in: text)
        )
        let to = position(
            from: beginningOfDocument,
            offset: range.upperBound.utf16Offset(in: text)
        )
        guard let from, let to else { return nil }
        return textRange(from: from, to: to)
    }
}
