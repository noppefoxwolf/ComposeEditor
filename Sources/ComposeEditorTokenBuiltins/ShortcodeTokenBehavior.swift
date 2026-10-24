import UIKit
import TokenTextView

/// Matches standalone `:shortcode:` tokens and identifies an active shortcode input context.
public struct ShortcodeTokenBehavior: TokenBehavior {
    public let detector: TokenDetector
    public let attachmentReplacement: TokenAttachmentReplacement?
    public let attributes: TokenMatchAttributes? = nil

    public init(
        maximumTokenLength: Int,
        priority: Int = 30,
        attachmentProvider: @escaping TokenAttachmentProvider
    ) {
        detector = TokenDetector(
            identifier: .shortcode,
            maximumTokenLength: max(1, maximumTokenLength),
            priority: priority,
            matchSearch: Self.makeSearch(),
            suggestionContextSearch: { text, selectedRange in
                guard selectedRange.length == 0 else { return nil }
                return TokenSuggestionMatch.firstRegexMatch(
                    in: text,
                    caretLocation: selectedRange.location,
                    maximumTokenLength: maximumTokenLength,
                    expression: Self.shortcodeContextExpression
                )
            }
        )
        attachmentReplacement = TokenAttachmentReplacement(provider: attachmentProvider)
    }

    private static func makeSearch() -> TokenMatchSearch {
        { text, range in
            guard let expression = shortcodeExpression else { return [] }
            return expression.matches(in: text as String, range: range).compactMap { result in
                guard result.numberOfRanges > 1 else { return nil }
                let identifier = text.substring(with: result.range(at: 1))
                return TokenMatch(
                    range: result.range,
                    identifier: identifier
                )
            }
        }
    }

    private static let shortcodeExpression = try? NSRegularExpression(
        pattern: #"(?<!\S):([A-Za-z0-9_+-]+):(?!\S)"#
    )

    private static let shortcodeContextExpression = try? NSRegularExpression(
        pattern: #"(?<!\S):([A-Za-z0-9_+-]+)(?::|(?!\S))"#
    )
}
