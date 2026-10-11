import Foundation

struct RegisteredTextMatch {
    let behavior: any TokenBehavior
    let match: TokenMatch

    func offset(by location: Int) -> RegisteredTextMatch {
        RegisteredTextMatch(
            behavior: behavior,
            match: TokenMatch(range: match.range.offset(by: location), identifier: match.identifier)
        )
    }
}

extension String {
    func registeredMatches(
        in range: NSRange,
        behaviors: [any TokenBehavior]
    ) -> [RegisteredTextMatch] {
        let candidates = behaviors.flatMap { behavior in
            tokenMatches(in: range, using: behavior.detector.matchSearch).map {
                RegisteredTextMatch(behavior: behavior, match: $0)
            }
        }.sorted {
            if $0.match.range.location != $1.match.range.location {
                return $0.match.range.location < $1.match.range.location
            }
            if $0.behavior.detector.priority != $1.behavior.detector.priority {
                return $0.behavior.detector.priority > $1.behavior.detector.priority
            }
            return $0.match.range.length > $1.match.range.length
        }

        var matches: [RegisteredTextMatch] = []
        for candidate in candidates where matches.last.map({
            NSMaxRange($0.match.range) <= candidate.match.range.location
        }) ?? true {
            matches.append(candidate)
        }
        return matches
    }
}
