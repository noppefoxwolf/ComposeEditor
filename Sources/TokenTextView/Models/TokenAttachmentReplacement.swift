import UIKit

/// Creates an attachment for a match. Return `nil` to leave the match editable as text.
public typealias TokenAttachmentProvider = @MainActor (
    _ match: TokenMatch,
    _ font: UIFont,
    _ attributes: [NSAttributedString.Key: Any]
) -> NSTextAttachment?

/// Defines how a detected token is replaced with an attachment.
public struct TokenAttachmentReplacement {
    public let provider: TokenAttachmentProvider

    public init(provider: @escaping TokenAttachmentProvider) {
        self.provider = provider
    }
}
