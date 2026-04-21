struct PlayerJoined: ServerMessage {
  let type: ServerMessageType = .playerJoined
  let code: String
  let player: ConnectionInit.PlayerInfo
}
