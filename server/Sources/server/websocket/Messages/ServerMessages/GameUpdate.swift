struct GameUpdateMessage: ServerMessage, @unchecked Sendable {
  let type: ServerMessageType = .gameUpdate
  var timeLeft: Int64? = nil
  var player: PlayerDTO? = nil
  var mice: [Mouse] = []
  var cats: [Cat] = []
  var activeVote: Voting? = nil
}
