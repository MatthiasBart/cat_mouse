import Foundation

class Controller {
    private var games: [String: Game] = [:]

    init() {}

    func createGame(with name: String) throws {
        if games[name] != nil {
            throw GameError.gameAlreadyExists
        }

        games[name] = Game()
    }

    func getGame(with name: String) -> Game? {
        games[name]
    }
}

enum GameError: Error {
    case gameAlreadyExists
    case playerNotExisting
    case playerHasUndefinedRole
    case noHoleFoundForID
    case noMouseFoundForID
}

public class Game {
    var players: [any Player]
    var subways: [Subway]
    var exits: [Exit]
    var votings: [Subway.ID: Voting]

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

    public init() {
        players = []
        subways = []
        exits = []
        votings = [:]
    }

    public func addMouse(name: String) {
        let mouse = Mouse()
        mouse.name = name
        self.players.append(mouse)
    }

    public func addCat(name: String) {
        let cat = Cat()
        cat.name = name
        self.players.append(cat)
    }

    public func startGame() {
        createSubways()

        positionPlayers()
    }

    func createSubways() { 
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
    }

    func positionPlayers() {
        let numberOfSubways = Int64(subways.count)
        for player in players {
            if let mouse = player as? Mouse {
                mouse.subway = Int64.random(in: 0...numberOfSubways)
            } else if player is Cat {
                player.position = .random
            }
        }
    }


    public func enter(exit: Int64, mouse: Int64) throws {
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

    public func leave(exit: Int64, mouse: Int64) throws {
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

    public func move(player: Int64, _ direction: Direction) throws {
        guard let player: (any Player) = cats.first(where: { $0.id == player }) ?? mice.first(where: { $0.id == player }) else {
            throw GameError.playerNotExisting
        }

        let newPosition = direction
                .newPosition(position: player.position)
                .inRange()

        player.position = newPosition
        // TODO check if cat hit mouse
    }
}
