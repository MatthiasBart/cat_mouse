import Vapor

extension RestController {
    func startGame(req: Request) async throws -> Response {
        guard let code = req.parameters.get("code"), !code.isEmpty else {
            throw Abort(.badRequest, reason: "Game code is missing")
        }

        guard let info = PlayerInfo(from: req.session) else {
            throw Abort(.unauthorized, reason: "Missing or invalid session")
        }

        guard info.code == code else {
            throw Abort(.forbidden, reason: "Session does not belong to this game")
        }

        do {
            try await gameService.startGame(code: code, requesterPlayerId: info.playerId)
        } catch let error as GameError {
            throw mapToAbort(error)
        }

        return Response(status: .noContent)
    }
}