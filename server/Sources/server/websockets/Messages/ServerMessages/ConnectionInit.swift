struct ConnectionInit: ServerMessage {
  struct PlayerInfo: Codable {
    let playerId: Int64
    let playerName: String
    let role: Role
    let isCreator: Bool
    let isComputer: Bool
  }

  let type: ServerMessageType = .connectionInit
  let code: String
  let started: Bool
  let currentPlayerId: Int64
  let players: [PlayerInfo]
}
