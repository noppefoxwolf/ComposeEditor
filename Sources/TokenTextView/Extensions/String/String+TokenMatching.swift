import Foundation

extension String {
    /// Finds valid, sorted, non-overlapping matches in a UTF-16 range.
    func tokenMatches(
        in range: NSRange,
        using search: TokenMatchSearch
    ) -> [TokenMatch] {
        let text = self as NSString
        guard range.location >= 0,
              range.length >= 0,
              range.location <= text.length,
              range.length <= text.length - range.location else { return [] }

        let matches = search(text, range)
            .filter { match in
                match.range.location >= range.location
                    && match.range.length > 0
                    && match.range.location <= text.length
                    && match.range.length <= text.length - match.range.location
                    && match.range.length <= NSMaxRange(range) - match.range.location
            }
            .sorted {
                if $0.range.location == $1.range.location {
                    return $0.range.length > $1.range.length
                }
                return $0.range.location < $1.range.location
            }

        var nonOverlappingMatches: [TokenMatch] = []
        for match in matches where nonOverlappingMatches.last.map({
            NSMaxRange($0.range) <= match.range.location
        }) ?? true {
            nonOverlappingMatches.append(match)
        }
        return nonOverlappingMatches
    }

    /// Rechecks a token after an attachment's placeholder character has changed context.
    func containsTokenMatch(
        replacingCharacterAt location: Int,
        with literalText: String,
        using search: TokenMatchSearch,
        maximumContextLength: Int
    ) -> Bool {
        let text = self as NSString
        guard location >= 0, location < text.length else { return false }

        let maximumLength = max(max(0, maximumContextLength), literalText.utf16.count)
        let contextLength = maximumLength < text.length ? maximumLength + 1 : text.length
        let contextStart = location - min(location, contextLength)
        let afterPlaceholder = location + 1
        let contextEnd = afterPlaceholder + min(text.length - afterPlaceholder, contextLength)
        let prefix = text.substring(with: NSRange(location: contextStart, length: location - contextStart))
        let suffix = text.substring(with: NSRange(location: location + 1, length: contextEnd - location - 1))
        let context = prefix + literalText + suffix
        let expectedRange = NSRange(location: prefix.utf16.count, length: literalText.utf16.count)
        let fullRange = NSRange(location: 0, length: (context as NSString).length)

        return context.tokenMatches(in: fullRange, using: search)
            .contains { $0.range == expectedRange }
    }
}
