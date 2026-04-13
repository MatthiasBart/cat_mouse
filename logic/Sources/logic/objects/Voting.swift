import Foundation

class Voting {
    typealias Votes = [Subway.ID: [Mouse]]
    let endTime: Date
    let votes: Votes
    let manager: Mouse

    init(endTime: Date = Date(), votes: Votes, manager: Mouse) {
        self.endTime = endTime
        self.votes = votes
        self.manager = manager
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

        var votes: [VotesDTO] = []
        for vote in self.votes {
            votes.append(.init(subwayId: vote.key, votes: Int64(votes.count)))
        }

        try container.encode(votes, forKey: .votes)
    }
}
