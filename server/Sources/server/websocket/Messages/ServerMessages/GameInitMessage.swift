struct GameInitMessage: ServerMessage {
  let type: ServerMessageType = .gameInit
  let code: String
  let role: Role
}
