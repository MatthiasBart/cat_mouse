import Vapor

struct PlayerInfo {
  static let playerIDKey = "playerId"
  static let playerNameKey = "playerName"
  static let codeKey = "code"
  static let roleKey = "role"

  let playerId: Int64
  let role: Role
  let playerName: String
  let code: String

  init(playerId: Int64, role: Role, playerName: String, code: String) {
    self.playerId = playerId
    self.playerName = playerName
    self.code = code
    self.role = role
  }

  init?(from session: Session) {
    guard
      let playerIdString: String = session.data[PlayerInfo.playerIDKey],
      let playerId = Int64(playerIdString),
      let playerName: String = session.data[PlayerInfo.playerNameKey],
      let code: String = session.data[PlayerInfo.codeKey],
      let roleRawValue: String = session.data[PlayerInfo.roleKey],
      let role = Role(rawValue: roleRawValue)
    else {
      return nil
    }
    self.playerId = playerId
    self.playerName = playerName
    self.code = code
    self.role = role
  }

  func save(to session: Session) {
    session.data[Self.playerIDKey] = String(self.playerId)
    session.data[Self.playerNameKey] = self.playerName
    session.data[Self.codeKey] = self.code
    session.data[Self.roleKey] = self.role.rawValue
  }
}
