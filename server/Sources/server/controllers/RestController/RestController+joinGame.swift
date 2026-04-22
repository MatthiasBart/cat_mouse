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

        let registration: GamesService.PlayerRegistration
        do {
            registration = try await gameService.joinGame(
                code: code, playerName: playerName, role: role)
        } catch let error as GameError {
            throw mapToAbort(error)
        }

        let info = PlayerInfo(
            playerId: registration.playerId,
            role: registration.role,
            playerName: playerName,
            code: code
        )
        info.save(to: req.session)

        req.logger.info("Player \(info.playerName) joined game \(info.code)")

        do {
            let message = PlayerJoinedMessage(
                code: code,
                player: ConnectionInitMessage.PlayerInfo(
                    playerId: registration.playerId,
                    playerName: playerName,
                    role: role,
                    isCreator: true,
                    isComputer: false
                )
            )
            await clientsService.broadcast(message: message, in: code)
        } catch {
            req.logger.warning("Failed to broadcast PLAYER_JOINED for code \(code): \(error)")
        }

        return JoinGameResponseBody(
            playerId: registration.playerId,
            role: role.rawValue,
            playerName: playerName,
            code: code
        )
    }
}
