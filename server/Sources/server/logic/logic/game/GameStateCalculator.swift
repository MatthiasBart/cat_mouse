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
                .mice(game.mice.filter { $0.subway == subway && $0.id != mouse.id })
                .cats(game.ghostCats[subway] ?? [])
                .fieldSize(width: Position.MAX_X, height: Position.MAX_Y)
                .subways(game.subways.filter { $0.id == subway }, exits: game.exits.filter { $0.subway.id == subway })
                .player(mouse)
                .timeLeft(Date().distance(to: game.endTime))
                .voting(game.votings[subway], allSubways: game.subways)
                .build()
        } else {
            return try GameUpdateMessageBuilder()
                .mice(game.mice.filter { $0.subway == nil && $0.caught == nil && $0.id != mouse.id })
                .cats(game.cats)
                .fieldSize(width: Position.MAX_X, height: Position.MAX_Y)
                .subways(game.subways, exits: game.exits)
                .player(mouse)
                .timeLeft(Date().distance(to: game.endTime))
                .build()
        }
    }

    func gameState(for cat: Cat) throws -> GameUpdateMessage {
        return try GameUpdateMessageBuilder()
            .mice(game.mice.filter { $0.subway == nil && $0.caught == nil })
            .cats(game.cats.filter { $0.id != cat.id })
            .fieldSize(width: Position.MAX_X, height: Position.MAX_Y)
            .subways(game.subways, exits: game.exits)
            .player(cat)
            .timeLeft(Date().distance(to: game.endTime))
            .build()
    }
}
