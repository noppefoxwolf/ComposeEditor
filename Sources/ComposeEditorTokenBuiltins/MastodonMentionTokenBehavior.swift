import UIKit
import TokenTextView

/// Matches local `@user` and federated `@user@host.example` Mastodon mentions, coloring them with tint color.
public struct MastodonMentionTokenBehavior: TokenBehavior {
    public let detector: TokenDetector
    public let attributes: TokenMatchAttributes?
    public let attachmentReplacement: TokenAttachmentReplacement? = nil

    public init(
        maximumTokenLength: Int = 320,
        priority: Int = 20
    ) {
        detector = TokenDetector(
            identifier: .mastodonMention,
            maximumTokenLength: max(1, maximumTokenLength),
            priority: priority,
            matchSearch: Self.makeSearch(),
            suggestionContextSearch: { text, selectedRange in
                guard selectedRange.length == 0,
                      let context = Self.mentionContext(
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

    private static func mentionContext(
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
        return mentionContextExpression?.matches(in: text as String, range: searchRange).compactMap { result in
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
            guard let expression = mentionExpression else { return [] }
            return expression.matches(in: text as String, range: range).compactMap { result in
                guard result.numberOfRanges > 1 else { return nil }
                let identifier = text.substring(with: result.range(at: 1))
                let parts = identifier.split(separator: "@", omittingEmptySubsequences: false)
                if parts.count == 2, !isValidHost(String(parts[1])) { return nil }
                return TokenMatch(
                    range: result.range,
                    identifier: identifier
                )
            }
        }
    }

    private static let mentionExpression = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\p{N}._%+-])@([A-Za-z0-9_]+(?:@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)?)(?![A-Za-z0-9_@])"#
    )
    private static let mentionContextExpression = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\p{N}._%+-])@([A-Za-z0-9_]*(?:@[A-Za-z0-9.-]*)?)"#
    )

    private static func isValidHost(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard host.utf8.count <= 253,
              labels.count >= 2,
              labels.allSatisfy({ label in
                  let bytes = Array(label.utf8)
                  guard !bytes.isEmpty, bytes.count <= 63,
                        isASCIIAlphanumeric(bytes[0]),
                        isASCIIAlphanumeric(bytes[bytes.count - 1]) else { return false }
                  return bytes.allSatisfy { isASCIIAlphanumeric($0) || $0 == 45 }
              }) else { return false }
        return true
    }

    private static func isASCIIAlphanumeric(_ byte: UInt8) -> Bool {
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
    }
}
