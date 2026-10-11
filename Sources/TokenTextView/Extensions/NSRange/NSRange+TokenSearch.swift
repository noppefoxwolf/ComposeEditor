import Foundation

extension NSRange {
    func offset(by amount: Int) -> NSRange {
        NSRange(location: location + amount, length: length)
    }

    /// Expands an edited range far enough to include a complete registered token and its boundaries.
    func expandedForTokenSearch(maximumTokenLength: Int, textLength: Int) -> NSRange {
        guard location >= 0, length >= 0, textLength >= 0 else {
            return NSRange(location: 0, length: max(0, textLength))
        }

        let changedLocation = min(location, textLength)
        let changedLength = min(length, textLength - changedLocation)
        let changedEnd = changedLocation + changedLength
        let maximumContextLength = min(max(0, maximumTokenLength), textLength)
        let contextLength = maximumContextLength < textLength ? maximumContextLength + 1 : textLength
        let start = max(0, changedLocation - contextLength)
        let end = changedEnd + min(contextLength, textLength - changedEnd)
        return NSRange(location: start, length: end - start)
    }
}
