import Vapor

struct PlayerSession {
  struct Output: Content {
    let playerId: Int64
    let role: Role
    let playerName: String
    let code: String
  }

  static let playerIDKey = "playerId"
  static let playerNameKey = "playerName"
  static let codeKey = "code"
  static let roleKey = "role"

  let playerId: Int64
  let role: Role
  let playerName: String
  let code: String
  let req: Request

  init(req: Request, playerId: Int64, role: Role, playerName: String, code: String) {
    self.playerId = playerId
    self.playerName = playerName
    self.code = code
    self.req = req
    self.role = role
  }

  init?(req: Request) {
    guard
      let playerIdString: String = req.session.data[PlayerSession.playerIDKey],
      let playerId = Int64(playerIdString),
      let playerName: String = req.session.data[PlayerSession.playerNameKey],
      let code: String = req.session.data[PlayerSession.codeKey],
      let roleRawValue: String = req.session.data[PlayerSession.roleKey],
      let role = Role(rawValue: roleRawValue)
    else {
      return nil
    }
    self.playerId = playerId
    self.playerName = playerName
    self.code = code
    self.req = req
    self.role = role
  }

  func save() {
    self.req.session.data[Self.playerIDKey] = String(self.playerId)
    self.req.session.data[Self.playerNameKey] = self.playerName
    self.req.session.data[Self.codeKey] = self.code
    self.req.session.data[Self.roleKey] = self.role.rawValue
  }

  var output: Output {
    Output(playerId: self.playerId, role: self.role, playerName: self.playerName, code: self.code)
  }
}
