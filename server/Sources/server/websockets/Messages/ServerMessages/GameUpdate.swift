struct GameUpdate: ServerMessage {
  var type: MessageType { .gameUpdate }
  let seq: Int
  let time: Int
}
