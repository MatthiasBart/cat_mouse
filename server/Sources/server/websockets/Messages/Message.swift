enum MessageType: String, Codable {
  case gameUpdate = "GAME_UPDATE"
  case gameOver = "GAME_OVER"
  case move = "MOVE"
  case error = "ERROR"
  // TODO: a lot more types needed
}

protocol Message {
  var type: MessageType { get }
}

protocol ClientMessage: Message, Decodable {
}

protocol ServerMessage: Message, Encodable {
}
