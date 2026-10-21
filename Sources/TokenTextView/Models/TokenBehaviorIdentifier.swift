/// An extensible identifier for a token behavior.
public struct TokenBehaviorIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
