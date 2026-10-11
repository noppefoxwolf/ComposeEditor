import Foundation

enum TokenContextSearchRange {
    static func aroundCaret(
        caretLocation: Int,
        maximumTokenLength: Int,
        textLength: Int
    ) -> NSRange {
        guard textLength > 0 else { return NSRange(location: 0, length: 0) }

        let caretLocation = min(max(0, caretLocation), textLength)
        let maximumContextLength = min(max(0, maximumTokenLength), textLength)
        let contextLength = maximumContextLength < textLength
            ? maximumContextLength + 1
            : textLength
        let start = max(0, caretLocation - contextLength)
        let end = caretLocation + min(contextLength, textLength - caretLocation)
        return NSRange(location: start, length: end - start)
    }
}
