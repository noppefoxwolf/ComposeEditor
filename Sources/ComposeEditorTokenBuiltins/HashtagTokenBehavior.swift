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
            identifier: .hashtag,
            maximumTokenLength: max(1, maximumTokenLength),
            priority: priority,
            matchSearch: Self.makeSearch(),
            suggestionContextSearch: { text, selectedRange in
                guard selectedRange.length == 0 else { return nil }
                return TokenSuggestionMatch.firstRegexMatch(
                    in: text,
                    caretLocation: selectedRange.location,
                    maximumTokenLength: maximumTokenLength,
                    expression: Self.hashtagContextExpression
                )
            }
        )
        attributes = TokenMatchAttributes { _, tintColor, _ in [.foregroundColor: tintColor] }
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
