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
    case noHoleFoundForID
    case noMouseFoundForID
}


class Game {
    var players: [any Player]
    var subways: [Subway]
    var exits: [Exit]
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
        exits = []
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

    func addMouse(name: String) {
        let mouse = Mouse()
        mouse.name = name
        self.players.append(mouse)
    }

    func addCat(name: String) {
        let cat = Cat()
        cat.name = name
        self.players.append(cat)
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
        let numberOfExits = Int64(cats.count * 3)
        var numberOfExitsLeft = numberOfExits
        var id: Subway.ID = 0

        while numberOfExitsLeft >= 1 {
            let exitsForSubway = Int64.random(in: 1...numberOfExitsLeft / 2)
            let subway = Subway(id: id)

            for exit_id in 0...exitsForSubway {
                exits.append(
                    Exit(id: Int64((id * numberOfExits) + exit_id), position: .random, subway: subway) // to have unique ids for each hole, id*numberOfExits is the offset for the subway, hole id is the offset for the hole in the subway
                )
            }
                    
            subways.append(subway)

            numberOfExitsLeft -= exitsForSubway
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

    func enter(exit: Int64, mouse: Int64) throws {
        guard let exit = exits.first(where: { $0.id == exit }) else { 
            throw GameError.noHoleFoundForID
        }
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }

        if mouse.isNear(exit) {
            mouse.subway = exit.subway.id
        }
    }

    func leave(exit: Int64, mouse: Int64) throws {
        guard let exit = exits.first(where: { $0.id == exit }) else { 
            throw GameError.noHoleFoundForID
        }
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }

        if mouse.subway == exit.subway.id { 
            mouse.subway = nil
            mouse.position = exit.position
        }
    }

    func move(player: Int64, _ direction: Direction) throws {
        guard let player: (any Player) = cats.first(where: { $0.id == player }) ?? mice.first(where: { $0.id == player }) else {
            throw GameError.playerNotExisting
        }

        let newPosition = direction
                .newPosition(position: player.position)
                .inRange()

        player.position = newPosition
        // check if cat hit mouse
    }
}

// create a Game Protocol for the methods
// create a Protocol for the Delegate methods

enum Direction: Decodable {
    case up
    case down
    case left
    case right

    func newPosition(position: Position) -> Position {
        var position = position
        let speed: Int64 = 20
        switch self {
            case .up: 
                position.y = position.y + speed
                return position
            case .down: 
                position.y = position.y - speed
                return position
            case .left: 
                position.x = position.x - speed
                return position
            case .right:
                position.x = position.x + speed
                return position
        }
    }
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
