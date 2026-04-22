import Vapor

extension RestController {
    struct CreateGameRequestQuery: Content {
        let role: String?
        let playerName: String?
    }

    struct CreateGameResponseBody: Content {
        let playerId: Int64
        let role: String
        let playerName: String
        let code: String
    }

    func createGame(req: Request) async throws -> CreateGameResponseBody {
        let playerRequest = try req.query.decode(CreateGameRequestQuery.self)
        let role = try parseRole(from: playerRequest.role)
        let playerName = parsePlayerName(from: playerRequest.playerName)

        let (code, registration) = await gameService.createGame(playerName: playerName, role: role)

        let info = PlayerInfo(
            playerId: registration.playerId,
            role: registration.role,
            playerName: playerName,
            code: code
        )
        info.save(to: req.session)

        req.logger.info("Player \(info.playerName) created game \(info.code)")

        return CreateGameResponseBody(
            playerId: registration.playerId,
            role: role.rawValue,
            playerName: playerName,
            code: code
        )
    }
}