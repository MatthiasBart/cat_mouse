/*struct GameUpdateMessage: ServerMessage, @unchecked Sendable {
  let type: ServerMessageType = .gameUpdate
  var timeLeft: Int64? = nil
  var player: PlayerDTO? = nil
  var mice: [Mouse] = []
  var cats: [Cat] = []
  var activeVote: Voting? = nil
}*/

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

struct GameUpdateMessage: ServerMessage, @unchecked Sendable {
  let type: ServerMessageType = .gameUpdate
  var timeLeft: Int64? = nil
  var player: PlayerDTO? = nil
  var mice: [Mouse] = []
  var cats: [Cat] = []
  var activeVote: Voting? = nil
  var subways: [GameUpdateSubwayDTO] = []
  var fieldSize: GameUpdateFieldSizeDTO? = nil
}