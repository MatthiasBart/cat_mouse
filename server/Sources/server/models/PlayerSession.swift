import Vapor

struct PlayerSession {
  struct Output: Content {
    let role: Role
    let playerName: String
    let code: String
  }

  static let playerNameKey = "playerName"
  static let codeKey = "code"

  let role: Role
  let playerName: String
  let code: String
  let req: Request

  init(req: Request, code: String) {
    self.playerName = req.query[PlayerSession.playerNameKey] ?? "Anonymous"
    self.code = code
    self.req = req
    self.role = .random  // TODO: not random role assignment
  }

  init?(req: Request) {
    guard
      let playerName: String = req.session.data[PlayerSession.playerNameKey],
      let code: String = req.session.data[PlayerSession.codeKey]
    else {
      return nil
    }
    self.playerName = playerName
    self.code = code
    self.req = req
    self.role = .random  // TODO: not random role assignment
  }

  func save() {
    self.req.session.data[Self.playerNameKey] = self.playerName
    self.req.session.data[Self.codeKey] = self.code
  }

  var output: Output {
    Output(role: self.role, playerName: self.playerName, code: self.code)
  }
}
