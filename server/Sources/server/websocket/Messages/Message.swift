enum ClientMessageType: String, Codable {
  case move = "MOVE"
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
  case gameUpdate = "GAME_UPDATE"
  case gameOver = "GAME_OVER"
  case error = "ERROR"
}

protocol ServerMessage: Encodable, Sendable {
  var type: ServerMessageType { get }
}

