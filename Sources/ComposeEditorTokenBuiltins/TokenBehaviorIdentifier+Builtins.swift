import TokenTextView

extension TokenBehaviorIdentifier {
    public static var hashtag: Self { Self(rawValue: "hashtag") }
    public static var shortcode: Self { Self(rawValue: "shortcode") }
    public static var mastodonMention: Self { Self(rawValue: "mastodon-mention") }
}
