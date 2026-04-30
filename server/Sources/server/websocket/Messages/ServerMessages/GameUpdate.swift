import Foundation 

struct GameUpdateSubwayDTO: Encodable {
  let id: Int64
  let exits: [GameUpdateExitDTO]
}

struct GameUpdateExitDTO: Encodable {
  let id: Int64
  let x: Int64
  let y: Int64
}

struct GameUpdateFieldSizeDTO: Encodable {
  let width: Int64
  let height: Int64
}

struct GameUpdateVotingDTO: Encodable {
    struct VoteCount: Encodable {
        let subwayId: Int64
        let votes: Int64
    }
    let timeLeft: Double
    let votes: [VoteCount]

    init(voting: Voting, allSubways: [Subway]) {
        timeLeft = Date().distance(to: voting.endTime)
        var counts: [Int64: Int64] = Dictionary(uniqueKeysWithValues: allSubways.map { ($0.id, 0) })
        for (_, subwayId) in voting.votes {
            counts[subwayId] = (counts[subwayId] ?? 0) + 1
        }
        votes = counts.map { VoteCount(subwayId: $0.key, votes: $0.value) }
            .sorted { $0.subwayId < $1.subwayId }
    }
}

struct GameUpdateMessage: ServerMessage, @unchecked Sendable {
  let type: ServerMessageType = .gameUpdate
  var timeLeft: Int64? = nil
  var player: PlayerDTO? = nil
  var mice: [Mouse] = []
  var cats: [Cat] = []
  var activeVote: GameUpdateVotingDTO? = nil
  var subways: [GameUpdateSubwayDTO] = []
  var fieldSize: GameUpdateFieldSizeDTO? = nil
}
