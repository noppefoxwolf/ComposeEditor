import Foundation
import TokenTextView

extension TokenSuggestionMatch {
    static func firstRegexMatch(
        in text: NSString,
        caretLocation: Int,
        maximumTokenLength: Int,
        expression: NSRegularExpression?
    ) -> TokenSuggestionMatch? {
        guard let expression else { return nil }
        let caret = min(max(0, caretLocation), text.length)
        let searchRange = TokenContextSearchRange.aroundCaret(
            caretLocation: caret,
            maximumTokenLength: maximumTokenLength,
            textLength: text.length
        )
        for result in expression.matches(in: text as String, range: searchRange) {
            let tokenRange = result.range
            let bodyRange = result.range(at: 1)
            guard caret > tokenRange.location,
                  caret >= bodyRange.location,
                  caret <= NSMaxRange(bodyRange) else { continue }
            return TokenSuggestionMatch(
                tokenRange: tokenRange,
                prefix: text.substring(with: NSRange(location: bodyRange.location, length: caret - bodyRange.location)),
                suffix: text.substring(with: NSRange(location: caret, length: NSMaxRange(bodyRange) - caret))
            )
        }
        return nil
    }
}
