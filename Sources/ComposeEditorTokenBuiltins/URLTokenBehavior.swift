import UIKit
import TokenTextView

/// Matches web URLs and colors them with the registered text view's tint color.
public struct URLTokenBehavior: TokenBehavior {
    public let detector: TokenDetector
    public let attributes: TokenMatchAttributes?
    public let attachmentReplacement: TokenAttachmentReplacement? = nil

    public init(
        maximumTokenLength: Int = 100,
        priority: Int = 30
    ) {
        detector = TokenDetector(
            identifier: "url",
            maximumTokenLength: max(1, maximumTokenLength),
            priority: priority,
            matchSearch: Self.makeSearch()
        )
        attributes = TokenMatchAttributes { _, tintColor, _ in [.foregroundColor: tintColor] }
    }

    private static func makeSearch() -> TokenMatchSearch {
        { text, range in
            guard let expression = linkDetector else { return [] }
            return expression.matches(in: text as String, range: range).compactMap { result in
                guard let url = result.url,
                      let scheme = url.scheme?.lowercased(),
                      scheme == "http" || scheme == "https" else { return nil }
                return TokenMatch(
                    range: result.range,
                    identifier: text.substring(with: result.range)
                )
            }
        }
    }

    private static let linkDetector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )
}
