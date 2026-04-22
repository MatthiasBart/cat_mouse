import Vapor

struct PlayerInfo {
  static let idKey = "id"
  static let nameKey = "name"
  static let codeKey = "code"
  static let roleKey = "role"

  let id: Int64
  let role: Role
  let name: String
  let roomCode: String

  init(id: Int64, role: Role, name: String, code: String) {
    self.id = id
    self.name = name
    self.roomCode = code
    self.role = role
  }

  init?(from session: Session) {
    guard
      let playerIdString: String = session.data[PlayerInfo.idKey],
      let playerId = Int64(playerIdString),
      let playerName: String = session.data[PlayerInfo.nameKey],
      let code: String = session.data[PlayerInfo.codeKey],
      let roleRawValue: String = session.data[PlayerInfo.roleKey],
      let role = Role(rawValue: roleRawValue)
    else {
      return nil
    }
    self.id = playerId
    self.name = playerName
    self.roomCode = code
    self.role = role
  }

  func save(to session: Session) {
    session.data[Self.idKey] = String(self.id)
    session.data[Self.nameKey] = self.name
    session.data[Self.codeKey] = self.roomCode
    session.data[Self.roleKey] = self.role.rawValue
  }
}
