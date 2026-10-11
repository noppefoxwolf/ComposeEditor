import UIKit
import TokenTextView

/// Matches Unicode hashtags and colors them with the registered text view's tint color.
public struct HashtagTokenBehavior: TokenBehavior {
    public let detector: TokenDetector
    public let attributes: TokenMatchAttributes?
    public let attachmentReplacement: TokenAttachmentReplacement? = nil

    public init(
        maximumTokenLength: Int = 256,
        priority: Int = 10
    ) {
        detector = TokenDetector(
            identifier: "hashtag",
            maximumTokenLength: max(1, maximumTokenLength),
            priority: priority,
            matchSearch: Self.makeSearch(),
            suggestionContextSearch: { text, selectedRange in
                guard selectedRange.length == 0,
                      let context = Self.hashtagContext(
                          in: text,
                          caretLocation: selectedRange.location,
                          maximumTokenLength: maximumTokenLength
                      ) else {
                    return nil
                }
                return context
            }
        )
        attributes = TokenMatchAttributes { _, tintColor, _ in [.foregroundColor: tintColor] }
    }

    private static func hashtagContext(
        in text: NSString,
        caretLocation: Int,
        maximumTokenLength: Int
    ) -> TokenSuggestionMatch? {
        let caretLocation = min(max(0, caretLocation), text.length)
        let searchRange = TokenContextSearchRange.aroundCaret(
            caretLocation: caretLocation,
            maximumTokenLength: maximumTokenLength,
            textLength: text.length
        )
        return hashtagContextExpression?.matches(in: text as String, range: searchRange).compactMap { result in
            let tokenRange = result.range
            let bodyRange = result.range(at: 1)
            guard caretLocation > tokenRange.location,
                  caretLocation <= NSMaxRange(tokenRange),
                  caretLocation >= bodyRange.location,
                  caretLocation <= NSMaxRange(bodyRange) else { return nil }
            return TokenSuggestionMatch(
                tokenRange: tokenRange,
                prefix: text.substring(with: NSRange(
                    location: bodyRange.location,
                    length: caretLocation - bodyRange.location
                )),
                suffix: text.substring(with: NSRange(
                    location: caretLocation,
                    length: NSMaxRange(bodyRange) - caretLocation
                ))
            )
        }.first
    }

    private static func makeSearch() -> TokenMatchSearch {
        { text, range in
            guard let expression = hashtagExpression else { return [] }
            return expression.matches(in: text as String, range: range).compactMap { result in
                guard result.numberOfRanges > 1 else { return nil }
                return TokenMatch(
                    range: result.range,
                    identifier: text.substring(with: result.range(at: 1))
                )
            }
        }
    }

    private static let hashtagExpression = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\p{N}_])#([\p{L}\p{N}\p{M}_]+)"#
    )
    private static let hashtagContextExpression = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\p{N}_])#([\p{L}\p{N}\p{M}_]*)"#
    )
}
