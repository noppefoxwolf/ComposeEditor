import UIKit

/// Bundles a token detector with optional match attributes and attachment replacement for registration.
public protocol TokenBehavior {
    var detector: TokenDetector { get }
    var attributes: TokenMatchAttributes? { get }
    var attachmentReplacement: TokenAttachmentReplacement? { get }
}

public extension TokenBehavior {
    var attributes: TokenMatchAttributes? { nil }
    var attachmentReplacement: TokenAttachmentReplacement? { nil }
}

/// Adapts a detector and optional effects to a registerable behavior.
public struct ClosureTokenBehavior: TokenBehavior {
    public let detector: TokenDetector
    public let attributes: TokenMatchAttributes?
    public let attachmentReplacement: TokenAttachmentReplacement?

    public init(
        detector: TokenDetector,
        attributes: TokenMatchAttributes? = nil,
        attachmentReplacement: TokenAttachmentReplacement? = nil
    ) {
        self.detector = detector
        self.attributes = attributes
        self.attachmentReplacement = attachmentReplacement
    }
}
