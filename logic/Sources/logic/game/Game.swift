import Foundation

enum GameError: Error {
    case gameAlreadyExists
    case playerNotExisting
    case playerHasUndefinedRole
    case noHoleFoundForID
    case noMouseFoundForID
    case votingAlreadyExists
    case votingNotExists
    case votingNotValid
    case mouseNotInSubway
    case notPermittedToEndVoting
}

public class Game {
    var players: [any Player]
    var subways: [Subway]
    var exits: [Exit]
    var votings: [Subway.ID: Voting]

    var endTime: Date? = nil

    private var nextId: Int64 = 1

    private func generateId() -> Int64 {
      let id = nextId
      nextId += 1
      return id
    }

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

    public var gameReady: Bool {
        mice.count + cats.count > 0 
    }

    static let duration: TimeInterval = 300

    public init() {
        players = []
        subways = []
        exits = []
        votings = [:]
    }

    public func addMouse(name: String) -> Int64{
        let mouse = Mouse()
        mouse.name = name
        mouse.id = generateId()
        self.players.append(mouse)
        return mouse.id
    }

    public func addCat(name: String) -> Int64 {
        let cat = Cat()
        cat.name = name
        cat.id = generateId()
        self.players.append(cat)
        return cat.id
    }

    public func endGame() {
        for mouse in mice { 
            mouse.totalTimeOnSurface += mouse.lastExit.distance(to: Date())
        }
    }

    public func startGame() {
        createSubways()

        positionPlayers()

        self.endTime = Date() + Game.duration
    }

    func createSubways() { 
        let numberOfExits = Int64(cats.count * 3)
        var numberOfExitsLeft = numberOfExits
        var id: Subway.ID = 0

        while numberOfExitsLeft > 1 {
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

//MARK: subway
extension Game { 
    public func enter(exit: Int64, mouse: Int64) throws {
        guard let exit = exits.first(where: { $0.id == exit }) else { 
            throw GameError.noHoleFoundForID
        }
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }

        if mouse.isNear(exit) {
            mouse.subway = exit.subway.id

            mouse.totalTimeOnSurface += mouse.lastExit.distance(to: Date())
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
            mouse.lastExit = Date()
        }

        //when manager mouse leaves, assign new manager to voting
        if let (subway, voting) = votings.first(where: { $1.manager.id == mouse.id }) {
            if let firstMouseInSubway = mice.filter({ $0.subway == subway }).first {
                voting.manager = firstMouseInSubway
            } else {
                voting.endTime = Date()
            }
        }
    }
}

//MARK: Voting
extension Game {
    public func startVoting(subway: Int64, manager: Int64) throws {
        if let voting = votings[subway] { 
            if !voting.isRunOut() {
                throw GameError.votingAlreadyExists
            }
        }   

        guard let mouse = mice.first(where: { $0.id == manager }) else { 
            throw GameError.noMouseFoundForID
        }
        
        votings[subway] = Voting(
            endTime: Date() + Voting.duration,
            manager: mouse
        )
    }

    public func vote(subway: Int64, mouse: Int64) throws { 
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }

        if mouse.subway == nil {
            throw GameError.mouseNotInSubway
        }

        guard let voting = votings[mouse.subway!] else { 
            throw GameError.votingNotExists
        }

        if voting.isRunOut() { 
            throw GameError.votingNotValid
        }

        voting.votes[mouse.id] = subway

        if voting.votes.count == mice.filter({ $0.subway == subway }).count {
            voting.endTime = Date()
        }
    }

    public func endVoting(subway: Int64, manager: Int64) throws {
        guard let voting = votings[subway] else { 
            throw GameError.votingNotExists
        }

        guard let mouse = mice.first(where: { $0.id == manager }) else { 
            throw GameError.noMouseFoundForID
        }

        guard mouse.id == voting.manager.id else {
            throw GameError.notPermittedToEndVoting
        }

        voting.endTime = Date() //TODO add way to flag as canceled
    }
}
