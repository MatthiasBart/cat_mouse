import Foundation
import Logging

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

private let logger = Logger(label: "Game")

protocol GameDelegate { 
    func gotCaught(_ mouse: Int64)
    func voteResult(_ subway: Int64, for mice: [Mouse.ID])
}

public class Game: @unchecked Sendable {
    var players: [any Player]
    var subways: [Subway]
    var exits: [Exit]
    var votings: [Subway.ID: Voting]
    var ghostCats: [Subway.ID: [GhostCat]]

    var endTime: Date = Date()

    var creator: Int64 
    var winner: (any Player)?

    var gameDelegate: (any GameDelegate)?

    var caughtMice: Int64 = 0

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
        logger.info("created")
        players = []
        subways = []
        exits = []
        votings = [:]
        creator = -1
        ghostCats = [:]
    }

    public func addMouse(name: String) -> Int64{
        logger.info("\(name) as mouse added")
        let mouse = Mouse()
        mouse.name = name
        mouse.id = Int64(UUID().hashValue)
        self.players.append(mouse)
        return mouse.id
    }

    public func addCat(name: String) -> Int64 {
        logger.info("\(name) as cat added")
        let cat = Cat()
        cat.name = name
        cat.id = Int64(UUID().hashValue)
        self.players.append(cat)
        return cat.id
    }

    public func checkGameState() { 
        for (subway, voting) in votings {
            let miceInSub = mice.filter({ $0.subway == subway })
            if voting.isRunOut() || miceInSub.count == voting.votes.count {
                let miceInSubIds = miceInSub.map { $0.id }
                let votingResult = voting.highestVotedSub()
                logger.info("voteResult in \(subway) result \(votingResult) for mice \(miceInSubIds)")
                gameDelegate?.voteResult(votingResult, for: miceInSubIds)        
                votings[subway] = nil
            }
        }

            if caughtMice == mice.count {
                logger.info("all mice caught, ending game")
                endGame()                
                endTime = Date()
            }

// TODO what happens if only one mouse is left
            let notCaughtMice = mice.filter { $0.caught == nil }
            let firstSubway = notCaughtMice.firstNonNil({ $0.subway })
            if notCaughtMice.allSatisfy({ $0.subway == firstSubway }) && firstSubway != nil && notCaughtMice.count != 1 { 
                logger.info("all mice in same subway, ending game")
                endGame()
                endTime = Date()
            }

            for (subway, ghostCatsForSub) in ghostCats {
                ghostCats[subway] = ghostCatsForSub.filter({ $0.lastSeen > (Date().addingTimeInterval(-5))}) 
            }
    }

    public func endGame() {
        for mouse in mice { 
            if mouse.subway != nil {
                mouse.totalTimeOnSurface += mouse.lastExit.distance(to: Date())
            }
        }
        
        logger.info("setting winner")
        if caughtMice == mice.count {
            winner = cats.max(by: { $0.caught.count < $1.caught.count })
        } else {
            winner = mice.max(by: { $0.totalTimeOnSurface < $1.totalTimeOnSurface })         
        }
    }

    public func startGame() {
        logger.info("starting game")
        createSubways()

        positionPlayers()

        self.endTime = Date() + Game.duration
    }

    public func leaveGame(player: Int64) {
        logger.info("removing player \(player)")
        players.removeAll(where: { $0.id == player })
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
                        Exit(
                            id: Int64((id * numberOfExits) + exit_id),
                            position: .random,
                            subway: subway
                            ) // to have unique ids for each hole, id*numberOfExits is the offset for the subway, hole id is the offset for the hole in the subway
                )
            }
                    
            subways.append(subway)

            numberOfExitsLeft -= exitsForSubway
            id += 1
        }

        logger.info("created \(subways.count) subways with \(exits.count) exits")
    }

    func positionPlayers() {
        let numberOfSubways = Int64(subways.count)
        logger.info("position players")
        for player in players {
            if let mouse = player as? Mouse {
                mouse.subway = Int64.random(in: 0..<numberOfSubways)
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

        logger.info("player \(player) moved \(direction.rawValue) to \(newPosition)")

        player.position = newPosition

        if let cat = player as? Cat {
            for mouse in mice.filter({ $0.subway == nil }) {
               if cat.position.isNear(mouse.position) && mouse.caught == nil {
                   cat.caught.append(mouse.id)
                   mouse.caught = cat.id
                   caughtMice += 1
                   logger.info("mouse \(mouse.id) caugth by \(cat.id)")
                   gameDelegate?.gotCaught(mouse.id)
               }
            }
        }
    }
}

//MARK: subway
extension Game { 
    public func enter(subway: Int64, mouse: Int64) throws {
        guard let subway = subways.first(where: { $0.id == subway }) else { 
            throw GameError.noHoleFoundForID
        }
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }

        ghostCats[subway.id] = cats.map{ GhostCat(from: $0) }

        mouse.subway = subway.id

        logger.info("mouse \(mouse) entered sub \(subway)")

        mouse.totalTimeOnSurface += mouse.lastExit.distance(to: Date())
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

        logger.info("mouse \(mouse) left sub \(exit.subway) via exit \(exit)")

        //when manager mouse leaves, assign new manager to voting
        if let (subway, voting) = votings.first(where: { $1.manager.id == mouse.id }) {
            if let firstMouseInSubway = mice.filter({ $0.subway == subway }).first {
                voting.manager = firstMouseInSubway
                logger.info("new manager \(firstMouseInSubway) for voting in sub \(subway)")
            } else {
                logger.info("voting ended since left mouse was only one")
                voting.endTime = Date()
            }
        }
    }
}

//MARK: Voting
extension Game {
    public func startVoting(manager: Int64) throws {
        guard let mouse = mice.first(where: { $0.id == manager }) else { 
            throw GameError.noMouseFoundForID
        }

        if mouse.subway == nil { 
            throw GameError.mouseNotInSubway
        }
        
        if let voting = votings[mouse.subway!] { 
            if !voting.isRunOut() {
                throw GameError.votingAlreadyExists
            }
        }   

        logger.info("voting started by \(manager)")

        votings[mouse.subway!] = Voting(
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

        logger.info("\(mouse.id) voted for \(subway)")
        voting.votes[mouse.id] = subway

        if voting.votes.count == mice.filter({ $0.subway == subway }).count {
            logger.info("all mice in sub \(mouse.subway ?? -1) voted for sub \(subway)")
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

        logger.info("voting in sub \(subway) got canceled by \(manager)")

        voting.endTime = Date() //TODO add way to flag as canceledtodo
    }
}
