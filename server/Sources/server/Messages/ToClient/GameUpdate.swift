struct GameUpdate: Codable {
  var type: MessageType { .gameUpdate }
  let seq: Int
  let time: Int
}
