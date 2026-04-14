import Foundation

struct GameStateCalculator {
    let game: Game 
    
    func computeGameState(for id: Int64) throws -> Data {
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

    func gameState(for mouse: Mouse) throws -> Data {
        if let subway = mouse.subway {
            return try GameStateDTOBuilder()
                .mice(game.mice.filter { $0.subway == subway })
                .voting(game.votings[subway])
                .player(mouse)
                .timeLeft(90)
                .build()
        } else {
            return try GameStateDTOBuilder()
                .mice([])
                .cats(game.cats)
                .player(mouse)
                .timeLeft(90)
                .build()
        }
    }

    func gameState(for cat: Cat) throws -> Data {
        return try GameStateDTOBuilder()
            .mice(game.mice.filter { $0.subway == nil })
            .cats(game.cats)
            .player(cat)
            .timeLeft(90)
            .build()
    }
}
