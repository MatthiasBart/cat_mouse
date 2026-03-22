enum MessageType: String, Codable {
  case gameUpdate = "GAME_UPDATE"
  case gameOver = "GAME_OVER"
  case move = "MOVE"
  // TODO: a lot more types needed
}

protocol Message: Codable {
  var type: MessageType { get }
}
