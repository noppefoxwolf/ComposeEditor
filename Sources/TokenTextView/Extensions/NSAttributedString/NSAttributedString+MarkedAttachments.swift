import UIKit

extension NSAttributedString.Key {
    static let markedTextLiteral = NSAttributedString.Key("TokenTextView.literal")
    static let markedTextBehavior = NSAttributedString.Key("TokenTextView.behavior")
    static let markedTextOriginalForegroundColor = NSAttributedString.Key(
        "TokenTextView.originalForegroundColor"
    )
}

struct MarkedAttachment {
    let range: NSRange
    let literalText: String
    let behaviorIdentifier: String
}

struct AttributedTextReplacement {
    let range: NSRange
    let text: NSAttributedString

    func offset(by location: Int) -> AttributedTextReplacement {
        AttributedTextReplacement(range: range.offset(by: location), text: text)
    }
}

extension NSAttributedString {
    func markedAttachment(atUTF16Location location: Int) -> MarkedAttachment? {
        guard location >= 0,
              location < length,
              attribute(.attachment, at: location, effectiveRange: nil) != nil,
              let literalText = attribute(.markedTextLiteral, at: location, effectiveRange: nil) as? String,
              let behaviorIdentifier = attribute(.markedTextBehavior, at: location, effectiveRange: nil) as? String else {
            return nil
        }
        return MarkedAttachment(
            range: NSRange(location: location, length: 1),
            literalText: literalText,
            behaviorIdentifier: behaviorIdentifier
        )
    }

    func markedAttachmentLocations(in range: NSRange) -> [Int] {
        guard range.location >= 0,
              range.length >= 0,
              range.location <= length,
              range.length <= length - range.location else { return [] }

        var locations: [Int] = []
        enumerateAttribute(.attachment, in: range, options: []) { value, attributeRange, _ in
            guard value != nil else { return }
            let start = max(range.location, attributeRange.location)
            let end = min(NSMaxRange(range), NSMaxRange(attributeRange))
            for location in start..<end where markedAttachment(atUTF16Location: location) != nil {
                locations.append(location)
            }
        }
        return locations
    }

    func literalReplacement(
        for attachment: MarkedAttachment,
        removingFinalCharacter: Bool = false
    ) -> AttributedTextReplacement? {
        guard attachment.range.location >= 0,
              attachment.range.location < length,
              markedAttachment(atUTF16Location: attachment.range.location)?.literalText == attachment.literalText else {
            return nil
        }

        var attributes = attributes(at: attachment.range.location, effectiveRange: nil)
        attributes.removeValue(forKey: .attachment)
        attributes.removeValue(forKey: .markedTextLiteral)
        attributes.removeValue(forKey: .markedTextBehavior)
        let text = removingFinalCharacter ? String(attachment.literalText.dropLast()) : attachment.literalText
        return AttributedTextReplacement(
            range: attachment.range,
            text: NSAttributedString(string: text, attributes: attributes)
        )
    }

    @MainActor
    func attachmentReplacement(
        for match: TokenMatch,
        behaviorIdentifier: String,
        using provider: TokenAttachmentProvider,
        fallbackFont: UIFont
    ) -> AttributedTextReplacement? {
        guard match.range.location >= 0,
              match.range.length > 0,
              match.range.location <= length,
              match.range.length <= length - match.range.location else { return nil }

        let attributes = attributes(at: match.range.location, effectiveRange: nil)
        let font = (attributes[.font] as? UIFont) ?? fallbackFont
        guard let attachment = provider(match, font, attributes) else { return nil }

        let literalText = (string as NSString).substring(with: match.range)
        let attachmentText = NSMutableAttributedString(attachment: attachment)
        let attachmentRange = NSRange(location: 0, length: attachmentText.length)
        attachmentText.addAttributes(attributes, range: attachmentRange)
        attachmentText.addAttribute(.markedTextLiteral, value: literalText, range: attachmentRange)
        attachmentText.addAttribute(.markedTextBehavior, value: behaviorIdentifier, range: attachmentRange)
        return AttributedTextReplacement(range: match.range, text: attachmentText)
    }

    func plainTextReplacingMarkedAttachments(in range: NSRange) -> String? {
        guard range.location >= 0,
              range.length >= 0,
              range.location <= length,
              range.length <= length - range.location else { return nil }

        let attachmentLocations = markedAttachmentLocations(in: range)
        guard !attachmentLocations.isEmpty else {
            return (string as NSString).substring(with: range)
        }

        let source = string as NSString
        let result = NSMutableString(capacity: range.length)
        var cursor = range.location
        for location in attachmentLocations {
            guard let attachment = markedAttachment(atUTF16Location: location) else { continue }
            result.append(source.substring(with: NSRange(location: cursor, length: location - cursor)))
            result.append(attachment.literalText)
            cursor = NSMaxRange(attachment.range)
        }
        result.append(source.substring(with: NSRange(location: cursor, length: NSMaxRange(range) - cursor)))
        return result as String
    }
}
