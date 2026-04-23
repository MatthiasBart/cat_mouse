import Foundation

struct GameStateCalculator: @unchecked Sendable {
    let game: Game 

    public init(game: Game) {
        self.game = game
    }
    
    // here distinguish between caught
    public func computeGameState(for id: Int64) async throws -> GameUpdateMessage {
        guard let player = game.players.first(where: { $0.id == id } ) else {
            throw GameError.playerNotExisting
        }

        if let cat = player as? Cat {
            return try gameState(for: cat)
        } else if let mouse = player as? Mouse { 
            return try gameState(for: mouse)
        } else {
            throw GameError.playerHasUndefinedRole
        }
    }

    func gameState(for mouse: Mouse) throws -> GameUpdateMessage {
        if let subway = mouse.subway {
            return try GameUpdateMessageBuilder()
                .mice(game.mice.filter { $0.subway == subway })
                .voting(game.votings[subway])
                .player(mouse)
                .cats(game.ghostCats[subway] ?? [])
                .timeLeft((game.endTime ?? Date()).distance(to: Date()))
                .build()
        } else {
            return try GameUpdateMessageBuilder()
                .mice(game.mice.filter { $0.subway == nil && $0.caught == nil })
                .cats(game.cats)
                .player(mouse)
                .timeLeft((game.endTime ?? Date()).distance(to: Date()))
                .build()
        }
    }

    func gameState(for cat: Cat) throws -> GameUpdateMessage {
        return try GameUpdateMessageBuilder()
            .mice(game.mice.filter { $0.subway == nil && $0.caught == nil })
            .cats(game.cats)
            .player(cat)
            .timeLeft((game.endTime ?? Date()).distance(to: Date()))
            .build()
    }
}
