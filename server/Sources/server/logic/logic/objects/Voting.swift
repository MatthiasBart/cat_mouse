import Foundation

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

    func highestVotedSub() -> Int64 {
        var voteCounts: [Subway.ID: Int64] = [:]
        for (mouse, subway) in votes {
            if let count = voteCounts[subway] { 
                voteCounts[subway] = count + 1
            } else { 
                voteCounts[subway] = 1
            }
        }

        var highestVotedSubway: Int64 = -1
        for (sub, count) in voteCounts {
            if highestVotedSubway == -1 { 
                highestVotedSubway = sub
            } else {
                if count > voteCounts[highestVotedSubway]! {
                   highestVotedSubway = sub 
                }
            }
        }

        return highestVotedSubway
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

    func isRunOut() -> Bool {
        self.endTime < Date()
    }
}
