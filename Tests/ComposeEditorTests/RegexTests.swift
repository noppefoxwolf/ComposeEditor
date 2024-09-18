import Testing
import Foundation
import RegexBuilder

@Suite
struct RegexTests {
    @Test func findLastComponent() async throws {
        let regex = Regex {
            Repeat(1...) {
                ZeroOrMore {
                    CharacterClass.whitespace
                }
                ChoiceOf {
                    Regex.hashtag
                    One(.url())
                }
            }
        }
        var text = "@username #hashtag #hashtag #hashtag"
        let range = text.matches(of: regex).last!.range
        text.removeSubrange(range)
        #expect(text == "@username")
    }
}
