import Foundation

class Controller {
    var games: [String: Game] = [:]

    init() {}

    func createGame(with name: String) throws {
        if games[name] != nil {
            throw GameError.gameAlreadyExists
        }

        games[name] = Game()
    }
}

enum GameError: Error {
    case gameAlreadyExists
    case playerNotExisting
    case playerHasUndefinedRole
}


class Game {
    var players: [any Player]
    var subways: [Subway]
    var votings: [Subway.ID:VotingRound]

    var cats: [Cat] { 
        players.compactMap {
            $0 as? Cat 
        }
    }

    var mice: [Mouse] { 
        players.compactMap {
            $0 as? Mouse
        }
    }

    private(set) var stop: Bool = false

    init() {
        players = []
        subways = []
        votings = [:]

        gameLoop()
    }

    func gameLoop() {
        while true {
            if stop {
                sendStopState()
                break
            }

            for player in players {
                sendGameState(for: player.id)
            }
        }
    }

    func sendStopState() {}

    func stopGame() {
        stop = true
    }

    func sendGameState(for id: Int64) {
        do {
            _ = try computeGameState(for: id)
        } catch {
            // send error
        }
   }

    func computeGameState(for id: Int64) throws -> Data {
        guard let player = players.first(where: { $0.id == id } ) else {
            throw GameError.playerNotExisting
        }

        if let cat = player as? Cat {
            return gameState(for: cat)
        } else if let mouse = player as? Mouse { 
            return gameState(for: mouse)
        } else {
            throw GameError.playerHasUndefinedRole
        }
    }

    func gameState(for mouse: Mouse) -> Data {
        if let subway = mouse.subway {
            return GameStateDTOBuilder()
                .mice(mice.filter { $0.subway == subway })
                .votes(.init(endTime: Date(), votings: [:]))
                .player(mouse)
                .timeLeft(90)
                .build()
        } else {
            return GameStateDTOBuilder()
                .mice([])
                .cats(cats)
                .votes(.init(endTime: Date(), votings: [:]))
                .player(mouse)
                .timeLeft(90)
                .build()
        }
    }

    func gameState(for cat: Cat) -> Data {
        return GameStateDTOBuilder()
            .mice([])
            .cats(cats)
            .player(cat)
            .timeLeft(90)
            .build()
    }


    func start() {
        var numberOfExits = cats.count * 3 
        var id: Subway.ID = 0

        while numberOfExits >= 1 {
            let exitsForSubway = Int.random(in: 1...numberOfExits / 2)
            var exits = [Hole]()
            for _ in 0...exitsForSubway {
                exits.append(
                    Hole(position: .random) 
                )
            }
                    
            subways.append(Subway(id: id, exits: exits))

            numberOfExits -= exitsForSubway
            id += 1
        }
        

        for player in players {
            if let mouse = player as? Mouse {
                mouse.subway = Int64.random(in: 0...id)
            } else if player is Cat {
                player.position = .random
            }
        }
    }

    func enterHole(_ id: Int64) {
    // ceck if mouse
    // check if near hole
    // enter
    }

    func leaveHole(_ id: Int64) {
        // leave through hole
    }

    func moved(_ id: Int64, _ direction: Direction) {
        // check if move is valid (map boundaries)
        // check if cat hits mouse (send caught)
        // make move 
    }
}

// create a Game Protocol for the methods
// create a Protocol for the Delegate methods

enum Direction: Decodable {
    case up
    case down
    case left
    case right
}

class GameStateDTOBuilder {
    private var dto = GameStateDTO()

    func mice(_ mice: [Mouse]) -> Self {
        return self
    }

    func cats(_ cats: [Cat]) -> Self {
        return self
    }

    func player(_ player: any Player) -> Self {
        return self
    }

    func votes(_ votes: VotingRound) -> Self {
        return self
    }

    func timeLeft(_ time: TimeInterval) -> Self { 
        return self
    }

    func build() -> Data {
        return Data()
    }
}

struct GameStateDTO: Encodable { 
// votings
// cats
// mice
// playerInfo
// timeleft in game
}
