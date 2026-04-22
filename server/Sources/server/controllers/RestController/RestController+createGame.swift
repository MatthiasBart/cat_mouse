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

        let (code, playerId) = await roomsService.createRoom(playerName: playerName, role: role)

        let info = PlayerInfo(
            id: playerId,
            role: role,
            name: playerName,
            code: code
        )
        info.save(to: req.session)

        req.logger.info("Player \(info.name) created game \(info.roomCode)")

        return CreateGameResponseBody(
            playerId: playerId,
            role: role.rawValue,
            playerName: playerName,
            code: code
        )
    }
}