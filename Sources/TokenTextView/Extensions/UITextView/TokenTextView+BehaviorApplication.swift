import UIKit

extension TokenTextView {
    func restoreMarkedAttachmentsToLiterals() {
        guard !isReplacingMatches else { return }
        let range = NSRange(location: 0, length: textStorage.length)
        let replacements: [AttributedTextReplacement] = textStorage.markedAttachmentLocations(in: range).compactMap { location in
            guard let attachment = textStorage.markedAttachment(atUTF16Location: location) else { return nil }
            return textStorage.literalReplacement(for: attachment)
        }
        guard !replacements.isEmpty else { return }

        let originalSelection = selectedRange.location
        var adjustedSelection = originalSelection
        for replacement in replacements where replacement.range.location < originalSelection {
            let replacedLength = min(replacement.range.length, originalSelection - replacement.range.location)
            adjustedSelection += replacement.text.length - replacedLength
        }

        isReplacingMatches = true
        defer { isReplacingMatches = false }
        performTextKit2Editing {
            textStorage.beginEditing()
            for replacement in replacements.sorted(by: { $0.range.location > $1.range.location }) {
                textStorage.replaceCharacters(in: replacement.range, with: replacement.text)
            }
            textStorage.endEditing()
        }
        selectedRange = NSRange(location: max(0, min(adjustedSelection, textStorage.length)), length: 0)
    }

    func replaceMatches(in changedRange: NSRange? = nil, registersUndo: Bool = false) {
        assertUsesTextKit2()
        guard !isReplacingMatches, !behaviors.isEmpty else { return }
        let textLength = textStorage.length
        guard textLength > 0 else { return }
        let maximumTokenLength = behaviors.map(\.detector.maximumTokenLength).max() ?? 0
        let scanRange = changedRange?.expandedForTokenSearch(
            maximumTokenLength: maximumTokenLength,
            textLength: textLength
        ) ?? NSRange(location: 0, length: textLength)

        let contextLength = maximumTokenLength < textLength ? maximumTokenLength + 1 : textLength
        let sourceStart = scanRange.location - min(scanRange.location, contextLength)
        let scanEnd = NSMaxRange(scanRange)
        let sourceEnd = scanEnd + min(contextLength, textLength - scanEnd)
        let sourceRange = NSRange(location: sourceStart, length: sourceEnd - sourceStart)
        let source = textStorage.attributedSubstring(from: sourceRange)
        let sourceText = source.string
        let localScanRange = NSRange(
            location: scanRange.location - sourceRange.location,
            length: scanRange.length
        )

        let matches = sourceText.registeredMatches(in: localScanRange, behaviors: behaviors)
        let attachmentMatchIndexes = Set(matches.indices.filter {
            matches[$0].behavior.attachmentReplacement != nil
        })
        var adjacentMatchIndexes = Set<Int>()
        for index in matches.indices where index + 1 < matches.count {
            guard attachmentMatchIndexes.contains(index),
                  attachmentMatchIndexes.contains(index + 1),
                  NSMaxRange(matches[index].match.range) == matches[index + 1].match.range.location else { continue }
            adjacentMatchIndexes.insert(index)
            adjacentMatchIndexes.insert(index + 1)
        }

        var edits: [AttributedTextReplacement] = []
        var literalizedAttachmentLocations = Set<Int>()

        for location in source.markedAttachmentLocations(in: localScanRange) {
            guard let attachment = source.markedAttachment(atUTF16Location: location) else { continue }
            let behavior = behaviors.first { $0.detector.identifier == attachment.behaviorIdentifier }
            let stillMatches = behavior.map {
                sourceText.containsTokenMatch(
                    replacingCharacterAt: location,
                    with: attachment.literalText,
                    using: $0.detector.matchSearch,
                    maximumContextLength: $0.detector.maximumTokenLength
                )
            } ?? false
            guard !stillMatches,
                  literalizedAttachmentLocations.insert(location).inserted,
                  let edit = source.literalReplacement(for: attachment) else { continue }
            edits.append(edit.offset(by: sourceRange.location))
        }

        let pairStart = max(0, localScanRange.location - 1)
        let pairEnd = min(source.length - 1, NSMaxRange(localScanRange))
        if pairStart < pairEnd {
            for location in pairStart..<pairEnd {
                let nextLocation = location + 1
                guard source.attribute(.attachment, at: location, effectiveRange: nil) != nil,
                      source.attribute(.attachment, at: nextLocation, effectiveRange: nil) != nil else { continue }
                for attachmentLocation in [location, nextLocation]
                where literalizedAttachmentLocations.insert(attachmentLocation).inserted {
                    if let attachment = source.markedAttachment(atUTF16Location: attachmentLocation),
                       let edit = source.literalReplacement(for: attachment) {
                        edits.append(edit.offset(by: sourceRange.location))
                    }
                }
            }
        }

        for index in matches.indices {
            let registeredMatch = matches[index]
            guard let attachmentReplacement = registeredMatch.behavior.attachmentReplacement else { continue }
            let match = registeredMatch.match
            let precedingLocation = match.range.location - 1
            let precedingCharacterIsAttachment = precedingLocation >= 0
                && source.attribute(.attachment, at: precedingLocation, effectiveRange: nil) != nil
            let followingLocation = NSMaxRange(match.range)
            let followingCharacterIsAttachment = followingLocation < source.length
                && source.attribute(.attachment, at: followingLocation, effectiveRange: nil) != nil

            for location in [precedingLocation, followingLocation]
            where location >= 0 && location < source.length
                && source.attribute(.attachment, at: location, effectiveRange: nil) != nil
                && literalizedAttachmentLocations.insert(location).inserted {
                if let attachment = source.markedAttachment(atUTF16Location: location),
                   let edit = source.literalReplacement(for: attachment) {
                    edits.append(edit.offset(by: sourceRange.location))
                }
            }

            guard !adjacentMatchIndexes.contains(index),
                  !precedingCharacterIsAttachment,
                  !followingCharacterIsAttachment,
                  let edit = source.attachmentReplacement(
                    for: match,
                    behaviorIdentifier: registeredMatch.behavior.detector.identifier,
                    using: attachmentReplacement.provider,
                    fallbackFont: font ?? .preferredFont(forTextStyle: .body)
                  ) else { continue }
            edits.append(edit.offset(by: sourceRange.location))
        }

        guard !edits.isEmpty else { return }
        isReplacingMatches = true
        defer { isReplacingMatches = false }

        let originalSelection = selectedRange.location
        var adjustedSelection = originalSelection
        for edit in edits where edit.range.location < originalSelection {
            let replacedLength = min(edit.range.length, originalSelection - edit.range.location)
            adjustedSelection += edit.text.length - replacedLength
        }

        if registersUndo {
            registerUndo(toRestore: NSAttributedString(attributedString: textStorage), selection: selectedRange)
        }
        performTextKit2Editing {
            textStorage.beginEditing()
            for edit in edits.sorted(by: { $0.range.location > $1.range.location }) {
                textStorage.replaceCharacters(in: edit.range, with: edit.text)
            }
            textStorage.endEditing()
        }
        assertUsesTextKit2()
        selectedRange = NSRange(location: max(0, min(adjustedSelection, textStorage.length)), length: 0)
    }
}
