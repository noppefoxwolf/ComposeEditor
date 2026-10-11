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
        supportedIdentifiers: Set<String>? = nil,
        attachmentProvider: @escaping TokenAttachmentProvider
    ) {
        detector = TokenDetector(
            identifier: "shortcode",
            maximumTokenLength: max(1, maximumTokenLength),
            priority: priority,
            matchSearch: Self.makeSearch(supportedIdentifiers: supportedIdentifiers),
            suggestionContextSearch: { text, selectedRange in
                guard selectedRange.length == 0,
                      let context = Self.shortcodeContext(
                          in: text,
                          caretLocation: selectedRange.location,
                          maximumTokenLength: maximumTokenLength
                      ) else {
                    return nil
                }
                return TokenSuggestionMatch(
                    tokenRange: context.range,
                    prefix: context.prefix,
                    suffix: context.suffix
                )
            }
        )
        attachmentReplacement = TokenAttachmentReplacement(provider: attachmentProvider)
    }

    private static func makeSearch(supportedIdentifiers: Set<String>?) -> TokenMatchSearch {
        { text, range in
            guard let expression = shortcodeExpression else { return [] }
            return expression.matches(in: text as String, range: range).compactMap { result in
                guard result.numberOfRanges > 1 else { return nil }
                let identifier = text.substring(with: result.range(at: 1))
                guard supportedIdentifiers.map({ $0.contains(identifier) }) ?? true else { return nil }
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

    private static func shortcodeContext(
        in text: NSString,
        caretLocation: Int,
        maximumTokenLength: Int
    ) -> (range: NSRange, prefix: String, suffix: String)? {
        let caretLocation = min(max(0, caretLocation), text.length)
        let searchRange = TokenContextSearchRange.aroundCaret(
            caretLocation: caretLocation,
            maximumTokenLength: maximumTokenLength,
            textLength: text.length
        )
        return shortcodeContextExpression?.matches(in: text as String, range: searchRange).compactMap { result in
            let tokenRange = result.range
            let nameRange = result.range(at: 1)
            guard caretLocation >= nameRange.location,
                  caretLocation <= NSMaxRange(nameRange) else { return nil }
            return (
                tokenRange,
                text.substring(with: NSRange(
                    location: nameRange.location,
                    length: caretLocation - nameRange.location
                )),
                text.substring(with: NSRange(
                    location: caretLocation,
                    length: NSMaxRange(nameRange) - caretLocation
                ))
            )
        }.first
    }

    private static let shortcodeContextExpression = try? NSRegularExpression(
        pattern: #"(?<!\S):([A-Za-z0-9_+-]+):?(?!\S)"#
    )
}
