import Foundation
import Testing
import UIKit
@testable import TokenTextView
@testable import ComposeEditorTokenBuiltins

@Suite
@MainActor
struct BuiltinBehaviorTests {
    private func makeTextView(_ text: String) -> TokenTextView {
        let textView = TokenTextView(frame: .zero, textContainer: nil)
        textView.text = text
        return textView
    }

    @Test func behaviorIdentifiersSupportBuiltinsAndCustomValues() {
        #expect(HashtagTokenBehavior().detector.identifier == .hashtag)
        #expect(URLTokenBehavior().detector.identifier == .url)
        #expect(MastodonMentionTokenBehavior().detector.identifier == .mastodonMention)
        #expect(TokenBehaviorIdentifier(rawValue: "shortcode") == .shortcode)
        let custom = TokenBehaviorIdentifier(rawValue: "custom")
        #expect(custom.rawValue == "custom")
        #expect(custom != .hashtag)
        #expect(Set([custom, TokenBehaviorIdentifier(rawValue: "custom")]).count == 1)
    }

    @Test func urlBehaviorMatchesWebURLsWithoutTrailingPunctuationOrEmail() {
        let behavior = URLTokenBehavior()
        let text = "😀 (https://example.com/path?q=swift#section), http://example.org. user@example.com"
        let matches = behavior.detector.matchSearch(text as NSString, NSRange(location: 0, length: text.utf16.count))

        #expect(matches.map(\.identifier) == ["https://example.com/path?q=swift#section", "http://example.org"])
        #expect(matches.first?.range == (text as NSString).range(of: "https://example.com/path?q=swift#section"))
        #expect(behavior.detector.suggestionContextSearch == nil)
    }

    @Test func urlHighlightIncludesFragmentsAndMentionsAndResetsAfterEditing() {
        let url = "https://example.com/@alice#section"
        let textView = makeTextView(url + " plain")
        textView.textColor = .systemOrange
        textView.register(HashtagTokenBehavior())
        textView.register(MastodonMentionTokenBehavior())
        textView.register(URLTokenBehavior())
        textView.applyBehaviorAttributes(in: nil)

        for location in 0..<url.utf16.count {
            #expect(textView.textStorage.attribute(.foregroundColor, at: location, effectiveRange: nil) as? UIColor == textView.tintColor)
        }
        #expect(textView.textStorage.attribute(.foregroundColor, at: url.utf16.count + 1, effectiveRange: nil) as? UIColor == .systemOrange)

        textView.textStorage.replaceCharacters(in: NSRange(location: 0, length: url.utf16.count), with: "plain")
        textView.applyBehaviorAttributes(in: NSRange(location: 0, length: 5))
        #expect(textView.textStorage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == .systemOrange)
    }

    @Test func hashtagBehaviorMatchesUnicodeTags() {
        let behavior = HashtagTokenBehavior()
        let text = "#日本語のタグ #Swift #"
        let matches = behavior.detector.matchSearch(text as NSString, NSRange(location: 0, length: (text as NSString).length))

        #expect(matches.map(\.identifier) == ["日本語のタグ", "Swift"])
    }

    @Test func mastodonMentionBehaviorMatchesLocalAndFederatedHandlesWithoutPartialMatches() {
        let behavior = MastodonMentionTokenBehavior()
        let text = "@local @noppe @noppe@mastodon.social @noppe@not-a-host user@example.com"
        let matches = behavior.detector.matchSearch(text as NSString, NSRange(location: 0, length: (text as NSString).length))

        #expect(matches.map(\.identifier) == ["local", "noppe", "noppe@mastodon.social"])
    }

    @Test func suggestionContextsRespectTokenBoundariesAndPunctuation() {
        let hashtag = HashtagTokenBehavior()
        let mention = MastodonMentionTokenBehavior()
        let shortcode = ShortcodeTokenBehavior(
            maximumTokenLength: 7,
            attachmentProvider: { _, _, _ in NSTextAttachment() }
        )

        #expect(suggestionContext(for: hashtag, in: "foo#tag", caret: 7) == nil)
        #expect(suggestionContext(for: hashtag, in: "(#tag", caret: 5)?.prefix == "tag")
        #expect(suggestionContext(for: mention, in: "foo@user", caret: 8) == nil)
        #expect(suggestionContext(for: mention, in: "(@user", caret: 6)?.prefix == "user")
        #expect(suggestionContext(for: shortcode, in: "X:star", caret: 6) == nil)
        #expect(suggestionContext(for: shortcode, in: "hoge:star", caret: 9) == nil)
        #expect(suggestionContext(for: shortcode, in: " :sta", caret: 5)?.prefix == "sta")
        #expect(suggestionContext(for: shortcode, in: " :sta!", caret: 5) == nil)
    }

    @Test func applyShortcodeSuggestionInsideClosedTokenPreservesFollowingWord() {
        let textView = makeTextView(":hogehoge:test")
        textView.selectedRange = NSRange(location: 5, length: 0)
        textView.register(ShortcodeTokenBehavior(
            maximumTokenLength: 32,
            attachmentProvider: { _, _, _ in nil }
        ))

        guard let context = textView.activeSuggestionContext else {
            Issue.record("Expected an active shortcode suggestion context")
            return
        }
        #expect(context.prefix == "hoge")
        #expect(context.suffix == "hoge")
        #expect(context.tokenRange == NSRange(location: 0, length: 10))

        textView.applySuggestion(":hogehoge:", for: context)

        #expect(textView.text == ":hogehoge: test")
        #expect(textView.selectedRange == NSRange(location: 11, length: 0))
    }

    @Test func applySuggestionReplacesWholeHashtagToken() {
        let textView = makeTextView("Use #sw now")
        let tokenRange = (textView.text as NSString).range(of: "#sw")
        textView.selectedRange = NSRange(location: NSMaxRange(tokenRange), length: 0)
        textView.register(HashtagTokenBehavior())

        guard let context = textView.activeSuggestionContext else {
            Issue.record("Expected an active hashtag suggestion context")
            return
        }

        textView.applySuggestion("#swift", for: context)

        #expect(textView.text == "Use #swift now")
    }

    @Test func applySuggestionAddsTrailingSpaceOnlyWhenNeeded() {
        let endOfText = makeTextView("Use #sw")
        endOfText.selectedRange = NSRange(location: endOfText.text.utf16.count, length: 0)
        endOfText.register(HashtagTokenBehavior())

        guard let endContext = endOfText.activeSuggestionContext else {
            Issue.record("Expected an active hashtag suggestion context")
            return
        }
        endOfText.applySuggestion("#swift", for: endContext)

        #expect(endOfText.text == "Use #swift ")
        #expect(endOfText.selectedRange == NSRange(location: endOfText.text.utf16.count, length: 0))

        let beforePunctuation = makeTextView("Use #sw!")
        let punctuationTokenEnd = (beforePunctuation.text as NSString).range(of: "#sw").location + 3
        beforePunctuation.selectedRange = NSRange(location: punctuationTokenEnd, length: 0)
        beforePunctuation.register(HashtagTokenBehavior())

        guard let punctuationContext = beforePunctuation.activeSuggestionContext else {
            Issue.record("Expected an active hashtag suggestion context before punctuation")
            return
        }
        beforePunctuation.applySuggestion("#swift", for: punctuationContext)

        #expect(beforePunctuation.text == "Use #swift!")

        let beforeExistingSpace = makeTextView("Use #sw ")
        let spacedTokenEnd = (beforeExistingSpace.text as NSString).range(of: "#sw").location + 3
        beforeExistingSpace.selectedRange = NSRange(location: spacedTokenEnd, length: 0)
        beforeExistingSpace.register(HashtagTokenBehavior())

        guard let spacedContext = beforeExistingSpace.activeSuggestionContext else {
            Issue.record("Expected an active hashtag suggestion context before existing whitespace")
            return
        }
        beforeExistingSpace.applySuggestion("#swift", for: spacedContext)

        #expect(beforeExistingSpace.text == "Use #swift ")
    }

    @Test func selectingHashtagSuggestionFromInsideTokenPreservesFollowingTypingColor() {
        let textView = makeTextView("#swift")
        let originalColor = UIColor.systemOrange
        textView.textColor = originalColor
        textView.register(HashtagTokenBehavior())
        textView.applyBehaviorAttributes(in: nil)

        textView.selectedRange = NSRange(location: 1, length: 0)
        textView.handleTextViewDidChangeSelection(textView)
        guard let context = textView.activeSuggestionContext else {
            Issue.record("Expected an active hashtag suggestion context")
            return
        }

        var typingAttributes = textView.typingAttributes
        typingAttributes[.foregroundColor] = textView.tintColor
        textView.typingAttributes = typingAttributes
        textView.applySuggestion("#swift", for: context)
        textView.applyBehaviorAttributes(in: NSRange(location: 0, length: textView.textStorage.length))
        textView.handleTextViewDidChangeSelection(textView)

        let caret = textView.selectedRange.location
        let insertedText = NSAttributedString(
            string: " x",
            attributes: textView.typingAttributes
        )
        textView.textStorage.replaceCharacters(
            in: NSRange(location: caret, length: 0),
            with: insertedText
        )
        textView.selectedRange = NSRange(location: caret + 1, length: 0)
        textView.applyBehaviorAttributes(in: NSRange(location: caret, length: insertedText.length))

        #expect(textView.textStorage.attribute(.foregroundColor, at: caret + 1, effectiveRange: nil) as? UIColor == originalColor)
        #expect(textView.typingAttributes[.foregroundColor] as? UIColor == originalColor)
    }

    @Test func applySuggestionReplacesWholeMentionToken() {
        let textView = makeTextView("Hi @ali!")
        let tokenRange = (textView.text as NSString).range(of: "@ali")
        textView.selectedRange = NSRange(location: NSMaxRange(tokenRange), length: 0)
        textView.register(MastodonMentionTokenBehavior())

        guard let context = textView.activeSuggestionContext else {
            Issue.record("Expected an active mention suggestion context")
            return
        }

        textView.applySuggestion("@alice", for: context)

        #expect(textView.text == "Hi @alice!")
    }

    @Test func applySuggestionIgnoresStaleContext() {
        let textView = makeTextView("#sw")
        textView.selectedRange = NSRange(location: textView.text.utf16.count, length: 0)
        textView.register(HashtagTokenBehavior())

        guard let staleContext = textView.activeSuggestionContext else {
            Issue.record("Expected an active hashtag suggestion context")
            return
        }

        textView.text = "#tag"
        textView.selectedRange = NSRange(location: textView.text.utf16.count, length: 0)
        textView.applySuggestion("#swift", for: staleContext)

        #expect(textView.text == "#tag")
    }

    @Test func suggestionContextSearchRangeStaysBoundedAroundCaret() {
        let middle = TokenContextSearchRange.aroundCaret(
            caretLocation: 50_000,
            maximumTokenLength: 256,
            textLength: 100_000
        )
        let end = TokenContextSearchRange.aroundCaret(
            caretLocation: 99_999,
            maximumTokenLength: 256,
            textLength: 100_000
        )

        #expect(middle == NSRange(location: 49_743, length: 514))
        #expect(end == NSRange(location: 99_742, length: 258))
        #expect(middle.length < 1_000)
    }

    @Test func builtinSuggestionContextsFindTokensInLongDocuments() {
        let prefix = String(repeating: "x ", count: 20_000)
        let suffix = String(repeating: " y", count: 20_000)
        let hashtag = HashtagTokenBehavior()
        let mention = MastodonMentionTokenBehavior()
        let shortcode = ShortcodeTokenBehavior(
            maximumTokenLength: 16,
            attachmentProvider: { _, _, _ in NSTextAttachment() }
        )

        let hashtagText = prefix + "(#日本語のタグ)" + suffix
        let hashtagToken = (hashtagText as NSString).range(of: "#日本語のタグ")
        let hashtagContext = suggestionContext(
            for: hashtag,
            in: hashtagText,
            caret: hashtagToken.location + 4
        )
        #expect(hashtagContext?.tokenRange == hashtagToken)
        #expect(hashtagContext?.prefix == "日本語")
        #expect(hashtagContext?.suffix == "のタグ")

        let mentionText = prefix + "(@noppe@host.example)" + suffix
        let mentionToken = (mentionText as NSString).range(of: "@noppe@host.example")
        let mentionContext = suggestionContext(
            for: mention,
            in: mentionText,
            caret: mentionToken.location + 4
        )
        #expect(mentionContext?.tokenRange == mentionToken)

        let shortcodeText = prefix + " :shortcode: " + suffix
        let shortcodeToken = (shortcodeText as NSString).range(of: ":shortcode:")
        let shortcodeContext = suggestionContext(
            for: shortcode,
            in: shortcodeText,
            caret: shortcodeToken.location + 5
        )
        #expect(shortcodeContext?.tokenRange == shortcodeToken)
    }

    @Test func mastodonMentionRejectsInvalidDomainLabels() {
        let behavior = MastodonMentionTokenBehavior()
        let text = "@user@-bad-.host.example @user@good-host.example"
        let matches = behavior.detector.matchSearch(text as NSString, NSRange(location: 0, length: (text as NSString).length))

        #expect(matches.map(\.identifier) == ["user@good-host.example"])
    }

    @Test func shortcodeBehaviorRequiresWhitespaceBoundaries() {
        let attachment: TokenAttachmentProvider = { _, _, _ in NSTextAttachment() }
        let behavior = ShortcodeTokenBehavior(maximumTokenLength: 7, attachmentProvider: attachment)
        let text = "X:star: :star: :star::star: :star:! :star:、"
        let matches = behavior.detector.matchSearch(text as NSString, NSRange(location: 0, length: (text as NSString).length))

        #expect(matches.map(\.identifier) == ["star"])
        #expect(behavior.attachmentReplacement != nil)
    }

    @Test func shortcodeProviderCanLeaveUnknownTokensAsEditableText() {
        let text = ":star: :unknown:"
        let textView = makeTextView(text)
        textView.register(ShortcodeTokenBehavior(
            maximumTokenLength: 12,
            attachmentProvider: { match, _, _ in
                match.identifier == "star" ? NSTextAttachment() : nil
            }
        ))

        textView.replaceMatches()

        let storage = textView.textStorage
        let supportedRange = (text as NSString).range(of: ":star:")
        let unsupportedRange = (storage.string as NSString).range(of: ":unknown:")
        #expect(storage.attribute(.attachment, at: supportedRange.location, effectiveRange: nil) != nil)
        #expect(storage.attribute(.attachment, at: unsupportedRange.location, effectiveRange: nil) == nil)
        #expect((storage.string as NSString).substring(with: unsupportedRange) == ":unknown:")
    }

    @Test func builtinBehaviorsRegisterOnTokenTextView() {
        let text = "#日本語のタグ @noppe@mastodon.social :star:"
        let textView = makeTextView(text)
        textView.register(HashtagTokenBehavior())
        textView.register(MastodonMentionTokenBehavior())
        textView.register(ShortcodeTokenBehavior(
            maximumTokenLength: 7,
            attachmentProvider: { _, _, _ in NSTextAttachment() }
        ))

        textView.replaceMatches()
        textView.applyBehaviorAttributes(in: nil)

        let storage = textView.textStorage
        let hashtagRange = (text as NSString).range(of: "#日本語のタグ")
        let mentionRange = (text as NSString).range(of: "@noppe@mastodon.social")
        let shortcodeRange = (text as NSString).range(of: ":star:")

        #expect(storage.attribute(.foregroundColor, at: hashtagRange.location, effectiveRange: nil) as? UIColor == textView.tintColor)
        #expect(storage.attribute(.foregroundColor, at: mentionRange.location, effectiveRange: nil) as? UIColor == textView.tintColor)
        #expect(storage.attribute(.attachment, at: shortcodeRange.location, effectiveRange: nil) != nil)
    }

    private func suggestionContext(
        for behavior: any TokenBehavior,
        in string: String,
        caret: Int
    ) -> TokenSuggestionMatch? {
        behavior.detector.suggestionContextSearch?(string as NSString, NSRange(location: caret, length: 0))
    }

    @Test func typingAfterHashtagDoesNotCarryTintIntoFollowingText() {
        let textView = makeTextView("#hashtag")
        let originalColor = textView.textColor ?? .label
        textView.register(HashtagTokenBehavior())
        textView.applyBehaviorAttributes(in: nil)

        let hashtagRange = NSRange(location: 0, length: (textView.text as NSString).length)
        textView.selectedRange = NSRange(location: NSMaxRange(hashtagRange), length: 0)
        textView.updateTypingAttributesForegroundColor()

        #expect(textView.typingAttributes[.foregroundColor] as? UIColor == originalColor)
        #expect(textView.textStorage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == textView.tintColor)

        let insertedText = " :star: hoge"
        let insertionRange = NSRange(location: textView.textStorage.length, length: 0)
        let insertedAttributedText = NSAttributedString(
            string: insertedText,
            attributes: textView.typingAttributes
        )
        textView.textStorage.replaceCharacters(in: insertionRange, with: insertedAttributedText)
        textView.applyBehaviorAttributes(in: NSRange(location: insertionRange.location, length: insertedAttributedText.length))

        let followingTextRange = (textView.text as NSString).range(of: "hoge")
        for location in followingTextRange.location..<NSMaxRange(followingTextRange) {
            #expect(textView.textStorage.attribute(.foregroundColor, at: location, effectiveRange: nil) as? UIColor == originalColor)
        }
    }

    @Test func clearingHashtagResetsTypingForegroundColor() {
        let textView = makeTextView("")
        let originalColor = UIColor.systemOrange
        textView.textColor = originalColor
        textView.text = "#hashtag"
        textView.register(HashtagTokenBehavior())
        textView.applyBehaviorAttributes(in: nil)

        var typingAttributes = textView.typingAttributes
        typingAttributes[.foregroundColor] = textView.tintColor
        textView.typingAttributes = typingAttributes
        textView.text = ""
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.applyBehaviorAttributes(in: nil)

        #expect(textView.typingAttributes[.foregroundColor] as? UIColor == originalColor)
    }
}
