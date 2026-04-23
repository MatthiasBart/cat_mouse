import Vapor

extension RestController {
    struct AddAIRequestQuery: Content {
        let role: String?
        let playerName: String?
    }

    func addAI(req: Request) async throws -> Response {
        guard let code = req.parameters.get("code"), !code.isEmpty else {
            throw Abort(.badRequest, reason: "Game code is missing")
        }

        guard let playerInfo = PlayerInfo(from: req.session) else {
            throw Abort(.unauthorized, reason: "Missing or invalid session")
        }

        guard playerInfo.roomCode == code else {
            throw Abort(.forbidden, reason: "Session does not belong to this game")
        }

        let playerRequest = try req.query.decode(AddAIRequestQuery.self)
        let role = try parseRole(from: playerRequest.role)
        
        if await roomsService.rooms[code]?.game.creator != playerInfo.id {
           throw Abort(.forbidden, reason: "Only game creators can add AI processes") 
        }

        do {
            try spawnAIProcess(logger: req.logger, code: code, role: role)
        } catch {
            req.logger.error("Failed to spawn AI process for game \(code): \(error)")
            throw Abort(.internalServerError, reason: "Failed to start AI process")
        }

        return Response(status: .noContent)
    }

    private func spawnAIProcess(logger: Logger, code: String, role: Role) throws {
        // NOTE: make sure the binary is built
        let aiBinaryPath = "../ai/game-ai"
        let roleArgument: String

        switch role {
        case .cat:
            roleArgument = "cat"
        case .mouse:
            roleArgument = "mouse"
        }

        let aiName = "ai-\(roleArgument)-\(UUID().uuidString.prefix(8))"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: aiBinaryPath)
        process.arguments = [
            "--host=http://localhost:8080",
            "--code=\(code)",
            "--role=\(roleArgument)",
            "--name=\(aiName)",
        ]

        logger.notice(
            "Spawning AI process path=\(aiBinaryPath) code=\(code) role=\(roleArgument) name=\(aiName)"
        )

        try process.run()

        logger.notice(
            "Spawned AI process pid=\(process.processIdentifier) for game \(code) as \(role.rawValue)"
        )
    }
}
