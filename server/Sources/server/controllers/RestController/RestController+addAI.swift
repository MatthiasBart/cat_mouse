import Vapor

extension RestController {
    private static let names = Set(["Tom", "Luna", "Leo", "Milo", "Bella", "Chloe", "Felix", "Salem", "Oliver", "Nala", "Loki", "Oreo", "Tiger", "Cleo", "Smokey", "Daisy", "Shadow", "Sam", "Paws", "Kitty", "Mickey", "Minnie", "Stuart", "Remy", "Bianca", "Speedy", "Gus", "Jaq", "Timothy", "Brain", "Pinky", "Ralph", "Hubie", "Bertie", "Cheddar", "Pip", "Squeak"])

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
        let rawPath = ProcessInfo.processInfo.environment["AI_BINARY_PATH"] ?? "../ai/game-ai"
        let aiBinaryPath = URL(fileURLWithPath: rawPath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)).standardized.path
        let roleArgument: String

        switch role {
        case .cat:
            roleArgument = "cat"
        case .mouse:
            roleArgument = "mouse"
        }

        let aiName: String = "\(Self.names.randomElement()!) AI"
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
