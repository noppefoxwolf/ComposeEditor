import RegexBuilder

extension Regex where Self.RegexOutput == Substring {
    public static var hashtag: Regex<Substring> {
        Regex {
            "#"
            OneOrMore(.word)
        }
    }
    
    public static var mention: Regex<Substring> {
        Regex {
            "@"
            OneOrMore(.word)
        }
    }
}
