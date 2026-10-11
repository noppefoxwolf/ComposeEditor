import Foundation

/// A partial-token context identified by a registered detector at the current caret position.
public struct TokenSuggestionContext: Sendable, Equatable {
    public let behaviorIdentifier: String
    public let text: String
    public let selectedRange: NSRange
    public let tokenRange: NSRange
    public let prefix: String
    public let suffix: String

    public init(
        behaviorIdentifier: String,
        text: String,
        selectedRange: NSRange,
        tokenRange: NSRange,
        prefix: String,
        suffix: String
    ) {
        self.behaviorIdentifier = behaviorIdentifier
        self.text = text
        self.selectedRange = selectedRange
        self.tokenRange = tokenRange
        self.prefix = prefix
        self.suffix = suffix
    }
}

/// The token range and text fragments around the caret returned by a detector.
public struct TokenSuggestionMatch: Sendable, Equatable {
    public let tokenRange: NSRange
    public let prefix: String
    public let suffix: String

    public init(tokenRange: NSRange, prefix: String, suffix: String) {
        self.tokenRange = tokenRange
        self.prefix = prefix
        self.suffix = suffix
    }
}

/// Finds a partial token at the current caret position.
public typealias TokenSuggestionContextSearch = (
    _ text: NSString,
    _ selectedRange: NSRange
) -> TokenSuggestionMatch?

