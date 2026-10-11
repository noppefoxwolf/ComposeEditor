import Foundation

/// A token found in text. `range` uses UTF-16 offsets, like UIKit text APIs.
public struct TokenMatch: Sendable, Equatable {
    public let range: NSRange
    public let identifier: String

    public init(range: NSRange, identifier: String) {
        self.range = range
        self.identifier = identifier
    }
}

/// Finds tokens in the requested UTF-16 range of the text.
public typealias TokenMatchSearch = (_ text: NSString, _ range: NSRange) -> [TokenMatch]
