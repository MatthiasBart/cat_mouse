import Vapor

struct PlayerSessionGuardMiddleware: AsyncMiddleware {
  func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard let playerInfo = PlayerInfo(from: req.session) else {
      throw Abort(.unauthorized, reason: "Missing or invalid session")
    }

    if let expectedCode = req.parameters.get("code"), expectedCode != playerInfo.roomCode {
      throw Abort(.forbidden, reason: "Session does not belong to this game")
    }

    return try await next.respond(to: req)
  }
}
