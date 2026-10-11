import UIKit

/// Supplies additional attributes for a matched token, such as the text view's tint color.
public typealias TokenMatchAttributesProvider = @MainActor (
    _ match: TokenMatch,
    _ tintColor: UIColor,
    _ originalAttributes: [NSAttributedString.Key: Any]
) -> [NSAttributedString.Key: Any]?

/// Defines attributes to apply to matches found by a token detector.
public struct TokenMatchAttributes {
    public let provider: TokenMatchAttributesProvider

    public init(provider: @escaping TokenMatchAttributesProvider) {
        self.provider = provider
    }
}
