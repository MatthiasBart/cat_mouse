import Vapor

extension RestController {
    struct JoinGameRequestQuery: Content {
        let role: String?
        let playerName: String?
    }

    struct JoinGameResponseBody: Content {
        let playerId: Int64
        let role: String
        let playerName: String
        let code: String
    }

    func joinGame(req: Request) async throws -> JoinGameResponseBody {
        guard let code = req.parameters.get("code"), !code.isEmpty else {
            throw Abort(.badRequest, reason: "Game code is missing")
        }

        let playerRequest = try req.query.decode(JoinGameRequestQuery.self)
        let role = try parseRole(from: playerRequest.role)
        let playerName = parsePlayerName(from: playerRequest.playerName)

        do {
            let playerId = try await roomsService.joinRoom(code: code, playerName: playerName, role: role)

        let info = PlayerInfo(
            id: playerId,
            role: role,
            name: playerName,
            code: code
        )
        info.save(to: req.session)

        req.logger.info("Player \(info.name) joined game \(info.roomCode)")

        return JoinGameResponseBody(
            playerId: playerId,
            role: role.rawValue,
            playerName: playerName,
            code: code
        )
        } catch let error as ServerError {
            throw mapToAbort(error)
        }
    }
}
