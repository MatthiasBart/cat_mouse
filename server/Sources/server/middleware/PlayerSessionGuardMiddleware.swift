import Vapor

struct PlayerSessionGuardMiddleware: AsyncMiddleware {
  func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard let session = PlayerSession(req: req) else {
      throw Abort(.unauthorized, reason: "Missing or invalid session")
    }

    if let expectedCode = req.parameters.get(PlayerSession.codeKey), expectedCode != session.code {
      throw Abort(.forbidden, reason: "Session does not belong to this game")
    }

    return try await next.respond(to: req)
  }
}
