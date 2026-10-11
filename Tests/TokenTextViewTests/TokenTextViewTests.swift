import Testing
import UIKit
@testable import TokenTextView

@Suite(.serialized)
@MainActor
struct TokenTextViewTests {
    private var images: [String: UIImage] {
        ["star": UIImage()]
    }

    private static let shortcodeRegex = try? NSRegularExpression(
        pattern: #":([A-Za-z0-9_+-]+):"#
    )
    private static let whitespaceDelimitedShortcodeRegex = try? NSRegularExpression(
        pattern: #"(?<!\S):([A-Za-z0-9_+-]+):(?!\S)"#
    )

    private static func searchColonShortcodes(text: NSString, range: NSRange) -> [TokenMatch] {
        guard let shortcodeRegex else { return [] }
        return shortcodeRegex.matches(in: text as String, range: range).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return TokenMatch(
                range: match.range,
                identifier: text.substring(with: match.range(at: 1))
            )
        }
    }

    private static func searchWhitespaceDelimitedShortcodes(text: NSString, range: NSRange) -> [TokenMatch] {
        guard let whitespaceDelimitedShortcodeRegex else { return [] }
        return whitespaceDelimitedShortcodeRegex.matches(in: text as String, range: range).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return TokenMatch(
                range: match.range,
                identifier: text.substring(with: match.range(at: 1))
            )
        }
    }

    private static func imageAttachment(image: UIImage, font: UIFont) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
        return attachment
    }

    private func makeTextView(_ text: String = "") -> TokenTextView {
        let images = images
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        textView.text = text
        textView.register(ClosureTokenBehavior(
            detector: TokenDetector(
                identifier: "shortcode",
                maximumTokenLength: 7,
                matchSearch: Self.searchColonShortcodes
            ),
            attachmentReplacement: TokenAttachmentReplacement(provider: { match, font, _ in
                guard let image = images[match.identifier] else { return nil }
                return Self.imageAttachment(image: image, font: font)
            })
        ))
        textView.replaceMatches()
        return textView
    }

    private func starAttachment() -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = images["star"]
        let value = NSMutableAttributedString(attachment: attachment)
        value.addAttribute(.markedTextLiteral, value: ":star:", range: NSRange(location: 0, length: value.length))
        value.addAttribute(.markedTextBehavior, value: "shortcode", range: NSRange(location: 0, length: value.length))
        return value
    }

    @Test func registeredShortcodeBecomesAttachment() {
        let textView = makeTextView("A :star:")

        #expect(textView.attributedText.attribute(.attachment, at: 2, effectiveRange: nil) != nil)
        #expect(textView.textLayoutManager != nil)
    }

    @Test func customSearchAndAttachmentProviderAreUsed() {
        let prefix = String(repeating: "a", count: 20_000)
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        textView.text = prefix + " "
        textView.register(ClosureTokenBehavior(
            detector: TokenDetector(
                identifier: "shortcode",
                maximumTokenLength: 6,
                matchSearch: { text, range in
                var matches: [TokenMatch] = []
                var searchLocation = range.location
                let searchEnd = NSMaxRange(range)
                while searchLocation < searchEnd {
                    let foundRange = text.range(
                        of: "[star]",
                        options: [],
                        range: NSRange(location: searchLocation, length: searchEnd - searchLocation)
                    )
                    guard foundRange.location != NSNotFound else { break }
                    matches.append(TokenMatch(range: foundRange, identifier: "custom-star"))
                    searchLocation = NSMaxRange(foundRange)
                }
                return matches
                }
            ),
            attachmentReplacement: TokenAttachmentReplacement(provider: { match, font, _ in
                guard match.identifier == "custom-star" else { return nil }
                let attachment = NSTextAttachment()
                attachment.image = UIImage(systemName: "star.fill")
                attachment.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
                return attachment
            })
        ))
        let insertionLocation = textView.attributedText.length
        _ = textView.shouldChangeText(
            in: NSRange(location: insertionLocation, length: 0),
            replacementText: "[star]"
        )
        textView.textStorage.replaceCharacters(
            in: NSRange(location: insertionLocation, length: 0),
            with: "[star]"
        )
        textView.replaceMatches(in: NSRange(location: insertionLocation, length: 6))

        #expect(textView.attributedText.attribute(.attachment, at: insertionLocation, effectiveRange: nil) != nil)
        #expect(textView.textLayoutManager != nil)
    }

    @Test func adjacentShortcodesStayLiteral() {
        let textView = makeTextView(":star::star:")

        #expect(textView.attributedText.string == ":star::star:")
        #expect(textView.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) == nil)
        #expect(textView.textLayoutManager != nil)
    }

    @Test func stringExtensionReturnsSortedValidatedNonOverlappingMatches() {
        let text = ":star::star:"
        let matches = text.tokenMatches(in: NSRange(location: 0, length: text.utf16.count)) { _, _ in
            [
                TokenMatch(range: NSRange(location: 6, length: 6), identifier: "second"),
                TokenMatch(range: NSRange(location: 3, length: 6), identifier: "overlapping"),
                TokenMatch(range: NSRange(location: 0, length: 6), identifier: "first"),
                TokenMatch(range: NSRange(location: 12, length: 1), identifier: "out-of-bounds")
            ]
        }

        #expect(matches.map(\.identifier) == ["first", "second"])
    }

    @Test func rangeExtensionExpandsTokenMatchSearchWithDocumentBounds() {
        let middle = NSRange(location: 4, length: 1)
            .expandedForTokenSearch(maximumTokenLength: 2, textLength: 10)
        let end = NSRange(location: 9, length: 1)
            .expandedForTokenSearch(maximumTokenLength: 2, textLength: 10)

        #expect(middle == NSRange(location: 1, length: 7))
        #expect(end == NSRange(location: 6, length: 4))
    }

    @Test func stringExtensionRechecksShortcodeBoundariesAroundAttachment() {
        let text = "\u{FFFC}X"

        #expect(!text.containsTokenMatch(
            replacingCharacterAt: 0,
            with: ":star:",
            using: Self.searchWhitespaceDelimitedShortcodes,
            maximumContextLength: 7
        ))
        #expect(" \u{FFFC}".containsTokenMatch(
            replacingCharacterAt: 1,
            with: ":star:",
            using: Self.searchWhitespaceDelimitedShortcodes,
            maximumContextLength: 7
        ))
    }

    @Test func attributedStringExtensionCreatesLiteralReplacementPreservingAttributes() {
        let original = NSMutableAttributedString(attributedString: starAttachment())
        original.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: 1))
        let attachment = original.markedAttachment(atUTF16Location: 0)

        let replacement = attachment.flatMap { original.literalReplacement(for: $0) }
        let deletionReplacement = attachment.flatMap {
            original.literalReplacement(for: $0, removingFinalCharacter: true)
        }

        #expect(replacement?.range == NSRange(location: 0, length: 1))
        #expect(replacement?.text.string == ":star:")
        #expect(replacement?.text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == .red)
        #expect(replacement?.text.attribute(.attachment, at: 0, effectiveRange: nil) == nil)
        #expect(deletionReplacement?.text.string == ":star")
        #expect(original.plainTextReplacingMarkedAttachments(in: NSRange(location: 0, length: 1)) == ":star:")
    }

    @Test func attributedStringExtensionBuildsAnAttachmentReplacement() {
        let source = NSAttributedString(string: " :star: ")
        let match = TokenMatch(range: NSRange(location: 1, length: 6), identifier: "star")
        let replacement = source.attachmentReplacement(
            for: match,
            behaviorIdentifier: "shortcode",
            using: { _, font, _ in Self.imageAttachment(image: UIImage(), font: font) },
            fallbackFont: .preferredFont(forTextStyle: .body)
        )

        #expect(replacement?.range == match.range)
        #expect(replacement?.text.attribute(.attachment, at: 0, effectiveRange: nil) != nil)
        #expect(replacement?.text.attribute(.markedTextLiteral, at: 0, effectiveRange: nil) as? String == ":star:")
    }

    @Test func typingAWordAfterAnAttachmentRestoresTheShortcodeToText() {
        let images = images
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        textView.text = " :star:"
        textView.register(ClosureTokenBehavior(
            detector: TokenDetector(
                identifier: "shortcode",
                maximumTokenLength: 7,
                matchSearch: Self.searchWhitespaceDelimitedShortcodes
            ),
            attachmentReplacement: TokenAttachmentReplacement(provider: { match, font, _ in
                guard let image = images[match.identifier] else { return nil }
                return Self.imageAttachment(image: image, font: font)
            })
        ))
        textView.replaceMatches()
        #expect(textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil) != nil)

        let insertionLocation = textView.textStorage.length
        _ = textView.shouldChangeText(
            in: NSRange(location: insertionLocation, length: 0),
            replacementText: "X"
        )
        textView.textStorage.replaceCharacters(
            in: NSRange(location: insertionLocation, length: 0),
            with: "X"
        )
        textView.replaceMatches(in: NSRange(location: insertionLocation, length: 1))

        #expect(textView.textStorage.string == " :star:X")
        #expect(textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil) == nil)
    }

    @Test func shortcodeNextToExistingAttachmentRestoresBothAsText() {
        let textView = makeTextView()
        textView.attributedText = starAttachment()
        textView.selectedRange = NSRange(location: 1, length: 0)
        _ = textView.shouldChangeText(
            in: NSRange(location: 1, length: 0),
            replacementText: ":star:"
        )
        textView.textStorage.replaceCharacters(
            in: NSRange(location: 1, length: 0),
            with: NSAttributedString(string: ":star:")
        )

        textView.replaceMatches()

        #expect(textView.attributedText.string == ":star::star:")
        #expect(textView.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) == nil)
        #expect(textView.textLayoutManager != nil)
    }

    @Test func removingSeparatorBetweenAttachmentsRestoresBothAsText() {
        let textView = makeTextView()
        let value = NSMutableAttributedString(attributedString: starAttachment())
        value.append(NSAttributedString(string: " "))
        value.append(starAttachment())
        textView.attributedText = value
        _ = textView.shouldChangeText(
            in: NSRange(location: 1, length: 1),
            replacementText: ""
        )
        textView.textStorage.deleteCharacters(in: NSRange(location: 1, length: 1))

        textView.replaceMatches(in: NSRange(location: 1, length: 0))

        #expect(textView.attributedText.string == ":star::star:")
        #expect(textView.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) == nil)
        #expect(textView.textLayoutManager != nil)
    }

    @Test func backspaceAfterAttachmentLeavesShortcodeWithoutFinalColon() {
        let textView = makeTextView()
        textView.attributedText = starAttachment()
        textView.selectedRange = NSRange(location: 1, length: 0)

        textView.deleteBackward()

        #expect(textView.attributedText.string == ":star")
        #expect(textView.textLayoutManager != nil)
    }

    @Test func cutAndPastePreservesAttachment() {
        let source = makeTextView()
        let destination = makeTextView()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let viewController = UIViewController()
        window.rootViewController = viewController
        viewController.view.addSubview(source)
        viewController.view.addSubview(destination)
        window.makeKeyAndVisible()

        source.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        destination.frame = CGRect(x: 0, y: 200, width: 400, height: 200)
        source.attributedText = starAttachment()
        source.selectedRange = NSRange(location: 0, length: 1)
        #expect(source.becomeFirstResponder())
        source.cut(nil)

        #expect(source.attributedText.string.isEmpty)
        #expect(UIPasteboard.general.string == ":star:")

        #expect(destination.becomeFirstResponder())
        destination.paste(nil)
        destination.replaceMatches()

        #expect(destination.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) != nil)
        #expect(source.textLayoutManager != nil)
        #expect(destination.textLayoutManager != nil)
    }

    @Test func editorUsesTextKit2() {
        let textView = makeTextView()

        #expect(textView.textLayoutManager != nil)
    }

    @Test func incrementalEditFindsShortcodeNearEndOfLongText() {
        let prefix = String(repeating: "a", count: 20_000)
        let textView = makeTextView("\(prefix) :star")
        let insertionLocation = textView.attributedText.length
        _ = textView.shouldChangeText(
            in: NSRange(location: insertionLocation, length: 0),
            replacementText: ":"
        )
        textView.textStorage.replaceCharacters(
            in: NSRange(location: insertionLocation, length: 0),
            with: ":"
        )

        textView.replaceMatches(in: NSRange(location: insertionLocation - 1, length: 1))

        #expect(textView.attributedText.attribute(.attachment, at: insertionLocation - 5, effectiveRange: nil) != nil)
        #expect(textView.textLayoutManager != nil)
    }

    @Test func incrementalMatchingReceivesOnlyTheBoundedTextRegion() {
        var searchedTextLengths: [Int] = []
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        textView.text = String(repeating: "a", count: 20_000) + "x"
        textView.register(ClosureTokenBehavior(
            detector: TokenDetector(
                identifier: "bounded-search",
                maximumTokenLength: 16,
                matchSearch: { text, _ in
                    searchedTextLengths.append(text.length)
                    return []
                }
            ),
            attributes: TokenMatchAttributes { _, _, _ in [:] }
        ))
        let changedRange = NSRange(location: textView.textStorage.length - 1, length: 1)

        textView.replaceMatches(in: changedRange)
        textView.applyBehaviorAttributes(in: changedRange)

        #expect(searchedTextLengths.count == 2)
        #expect(searchedTextLengths.allSatisfy { $0 < 100 })
    }

    @Test func incrementalEditDoesNotRescanDistantText() {
        let prefix = String(repeating: "a", count: 20_000)
        var isStarAvailable = false
        let images = images
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        textView.text = ":star:" + prefix + "x"
        textView.register(ClosureTokenBehavior(
            detector: TokenDetector(
                identifier: "shortcode",
                maximumTokenLength: 7,
                matchSearch: Self.searchColonShortcodes
            ),
            attachmentReplacement: TokenAttachmentReplacement(provider: { match, font, _ in
                guard isStarAvailable, let image = images[match.identifier] else { return nil }
                return Self.imageAttachment(image: image, font: font)
            })
        ))
        isStarAvailable = true
        let insertionLocation = textView.attributedText.length
        textView.textStorage.replaceCharacters(
            in: NSRange(location: insertionLocation, length: 0),
            with: ":"
        )
        textView.replaceMatches(in: NSRange(location: insertionLocation, length: 1))

        #expect(textView.attributedText.string.hasPrefix(":star:"))
        #expect(textView.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) == nil)
        #expect(textView.textLayoutManager != nil)
    }
}
