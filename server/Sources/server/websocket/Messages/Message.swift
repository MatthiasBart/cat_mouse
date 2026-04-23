enum ClientMessageType: String, Codable {
  case move = "MOVE"
  case leaveSubway = "LEAVE_SUBWAY"
  case enterSubway = "ENTER_SUBWAY"
  case startVote = "START_VOTE"
  case leaveGame = "LEAVE_GAME"
  case voteDecision = "VOTE_DECISION"

}

protocol ClientMessage: Decodable, Sendable {
  var type: ClientMessageType { get }
}

struct AnyClientMessage: ClientMessage {
  var type: ClientMessageType
}

enum ServerMessageType: String, Codable {
  case connectionInit = "CONNECTION_INIT"
  case playerJoined = "PLAYER_JOINED"
  case gameInit = "GAME_INIT"
  case mouseCaught = "CAUGHT"
  case voteResult = "VOTE_RESULT"
  case gameUpdate = "GAME_UPDATE"
  case gameEnded = "GAME_ENDED"
  case error = "ERROR"
}

protocol ServerMessage: Encodable, Sendable {
  var type: ServerMessageType { get }
}

