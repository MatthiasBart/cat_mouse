struct GameUpdate: ServerMessage {
  let type: ServerMessageType
  let seq: Int
  let time: Int

  init(seq: Int, time: Int) {
    self.type = .gameUpdate
    self.seq = seq
    self.time = time
  }
}
