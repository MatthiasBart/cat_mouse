enum ClientMessageType: String, Codable {
  case move = "MOVE"
}

protocol ClientMessage: Decodable {
  var type: ClientMessageType { get }
}

enum ServerMessageType: String, Codable {
  case gameUpdate = "GAME_UPDATE"
  case gameOver = "GAME_OVER"
  case error = "ERROR"
}

protocol ServerMessage: Encodable {
  var type: ServerMessageType { get }
}
