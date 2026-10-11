import UIKit

extension TokenTextView {
    func applyBehaviorAttributes(in changedRange: NSRange?) {
        let storage = textStorage
        guard storage.length > 0 else {
            updateTypingAttributesForegroundColor()
            return
        }

        let range: NSRange
        if let changedRange {
            range = changedRange.expandedForTokenSearch(
                maximumTokenLength: behaviors.map(\.detector.maximumTokenLength).max() ?? 0,
                textLength: storage.length
            )
        } else {
            range = NSRange(location: 0, length: storage.length)
        }
        guard range.length > 0 else { return }

        var originalColors: [(range: NSRange, color: UIColor)] = []
        storage.enumerateAttribute(.markedTextOriginalForegroundColor, in: range, options: []) { value, effectiveRange, _ in
            guard let color = value as? UIColor else { return }
            originalColors.append((effectiveRange, color))
        }

        storage.beginEditing()
        for originalColor in originalColors {
            originalTypingForegroundColor = originalColor.color
            storage.addAttribute(.foregroundColor, value: originalColor.color, range: originalColor.range)
            storage.removeAttribute(.markedTextOriginalForegroundColor, range: originalColor.range)
        }

        let sourceText = storage.attributedSubstring(from: range).string
        let localRange = NSRange(location: 0, length: (sourceText as NSString).length)
        let matches = sourceText
            .registeredMatches(in: localRange, behaviors: behaviors)
            .map { $0.offset(by: range.location) }
        for registeredMatch in matches {
            guard let attributes = registeredMatch.behavior.attributes else { continue }
            let attributesProvider = attributes.provider
            let match = registeredMatch.match
            var foregroundColors: [(range: NSRange, color: UIColor)] = []
            storage.enumerateAttribute(.foregroundColor, in: match.range, options: []) { value, effectiveRange, _ in
                let color = value as? UIColor ?? textColor ?? .label
                foregroundColors.append((effectiveRange, color))
            }
            if let originalColor = foregroundColors.first?.color {
                originalTypingForegroundColor = originalColor
            }
            for originalColor in foregroundColors {
                storage.addAttribute(
                    .markedTextOriginalForegroundColor,
                    value: originalColor.color,
                    range: originalColor.range
                )
            }
            guard let attributes = attributesProvider(
                match,
                tintColor,
                storage.attributes(at: match.range.location, effectiveRange: nil)
            ) else { continue }
            storage.addAttributes(attributes, range: match.range)
        }
        storage.endEditing()
        updateTypingAttributesForegroundColor()
    }

    func updateTypingAttributesForegroundColor() {
        guard textStorage.length > 0 else {
            var attributes = typingAttributes
            attributes[.foregroundColor] = originalTypingForegroundColor ?? textColor ?? .label
            attributes.removeValue(forKey: .markedTextOriginalForegroundColor)
            typingAttributes = attributes
            return
        }
        guard selectedRange.length == 0 else { return }

        let location = min(max(selectedRange.location, 0), textStorage.length)
        let candidateLocations = [location, location - 1].filter { $0 >= 0 && $0 < self.textStorage.length }
        let originalColor = candidateLocations.lazy.compactMap { location in
            self.textStorage.attribute(
                .markedTextOriginalForegroundColor,
                at: location,
                effectiveRange: nil
            ) as? UIColor
        }.first
        guard let originalColor else { return }

        var attributes = typingAttributes
        attributes[.foregroundColor] = originalColor
        attributes.removeValue(forKey: .markedTextOriginalForegroundColor)
        typingAttributes = attributes
    }
}
