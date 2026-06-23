import Foundation

/// Tracks an in-progress vote among the mice in one subway for which subway to surface next.
/// History constraint (client-responsible, per s4): `votes` must only be mutated while
/// `!isRunOut()`; once run out, callers must treat this `Voting` as closed.
class Voting {
    typealias Votes = [Mouse.ID: Subway.ID]
    var endTime: Date
    var votes: Votes
    var manager: Mouse

    init(endTime: Date = Date(), votes: Votes = [:], manager: Mouse) {
        self.endTime = endTime
        self.votes = votes
        self.manager = manager
    }

    /// Postcondition: returns the subway with the most votes, or `nil` if there are no votes
    /// yet. Ties are broken arbitrarily by `max(by:)` - an accepted simplification, not a
    /// guaranteed invariant.
    func highestVotedSub() -> Subway.ID? {
        var voteCounts: [Subway.ID: Int64] = [:]
        for (_, subway) in votes {
            voteCounts[subway] = (voteCounts[subway] ?? 0) + 1
        }
        return voteCounts.max(by: { $0.value < $1.value })?.key
    }
}

extension Voting: Encodable {
    private struct VotesDTO: Encodable {
        let subwayId: Int64
        let votes: Int64
    }

    enum CodingKeys: String, CodingKey {
        case timeLeft
        case votes
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Date().distance(to: endTime), forKey: .timeLeft)

        var voteDtos: [VotesDTO] = []
        var voteCounts: [Subway.ID: Int64] = [:]

        for vote in self.votes {
            voteCounts[vote.value] = (voteCounts[vote.value] ?? 0) + 1    
        }

        for voteCount in voteCounts {
            voteDtos.append(.init(subwayId: voteCount.key, votes: voteCount.value))
        }

        try container.encode(voteDtos, forKey: .votes)
    }
}

extension Voting {
    static let duration: TimeInterval = 45

    /// Postcondition: `true` iff `endTime` has passed; once true, callers must treat this
    /// `Voting` as closed.
    func isRunOut() -> Bool {
        self.endTime < Date()
    }
}
