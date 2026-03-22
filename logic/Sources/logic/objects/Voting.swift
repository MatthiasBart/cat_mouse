import Foundation

class VotingRound {
    typealias Votings = [Int64: [Mouse]]
    let endTime: Date
    let votings: Votings

    init(endTime: Date = Date(), votings: Votings) {
        self.endTime = endTime
        self.votings = votings
    }
}
