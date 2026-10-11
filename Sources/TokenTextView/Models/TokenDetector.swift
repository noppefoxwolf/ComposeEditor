import Foundation

/// Finds complete tokens and identifies a partial token at the caret.
public struct TokenDetector {
    public let identifier: String
    /// Maximum token length in UTF-16 code units, used to bound incremental scans.
    public let maximumTokenLength: Int
    public let priority: Int
    public let matchSearch: TokenMatchSearch
    public let suggestionContextSearch: TokenSuggestionContextSearch?

    public init(
        identifier: String,
        maximumTokenLength: Int,
        priority: Int = 0,
        matchSearch: @escaping TokenMatchSearch,
        suggestionContextSearch: TokenSuggestionContextSearch? = nil
    ) {
        precondition(maximumTokenLength > 0, "maximumTokenLength must be positive.")
        self.identifier = identifier
        self.maximumTokenLength = maximumTokenLength
        self.priority = priority
        self.matchSearch = matchSearch
        self.suggestionContextSearch = suggestionContextSearch
    }
}
