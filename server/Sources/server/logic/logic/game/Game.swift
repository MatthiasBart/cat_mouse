import Foundation
import Logging

/// Errors a `Game` operation can throw when its preconditions aren't met (unknown id, wrong
/// state for the requested transition, etc).
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

/// Callback contract for whoever hosts a `Game` (here: `Room`).
/// Precondition: an implementor must be installed via `gameDelegate` before `move`/`vote` are
/// called, otherwise notifications are silently dropped (the property is `Optional`).
/// `gotCaught`/`voteResult` are invoked synchronously, inline with the triggering `Game` call;
/// implementors must not block.
protocol GameDelegate {
    func gotCaught(_ mouse: Int64)
    func voteResult(_ subway: Int64, for mice: [Mouse.ID])
}

/// Owns one running game: its players, subways, and the rules for placement, movement, catching,
/// and ending the game.
///
/// Invariant: `caughtMice` equals the number of mice in `players` whose `caught != nil`.
public class Game: @unchecked Sendable {
    private(set) var players: [any Player]
    private(set) var subways: [Subway]

    private(set) var endTime: Date = Date()

    private(set) var creator: Int64?
    private(set) var winner: (any Player)?

    var gameDelegate: (any GameDelegate)?

    private var caughtMice: Int64 = 0

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
        mice.count >= 2 && cats.count >= 1 
    }

    static let duration: TimeInterval = 300

    public init() {
        logger.info("created")
        players = []
        subways = []
        creator = nil
    }

    /// Postcondition: a new `Mouse` is appended to `players` and its id returned; if this is
    /// the first player added overall, it becomes `creator`.
    public func addMouse(name: String) -> Int64 {
        let mouse = Mouse(id: Int64(UUID().hashValue), name: name)
        self.players.append(mouse)
        if players.count == 1 { creator = mouse.id }
        logger.info("\(name) as mouse added")
        return mouse.id
    }

    /// Postcondition: a new `Cat` is appended to `players` and its id returned; if this is
    /// the first player added overall, it becomes `creator`.
    public func addCat(name: String) -> Int64 {
        let cat = Cat(id: Int64(UUID().hashValue), name: name)
        self.players.append(cat)
        if players.count == 1 { creator = cat.id }
        logger.info("\(name) as cat added")
        return cat.id
    }

    /// Invariant-maintenance step, expected to be polled regularly. Postconditions per call: any
    /// `Voting` that ran out or received votes from every mouse currently in its subway is
    /// resolved and removed; the game ends (`endGame()`) once every mouse is caught, or once
    /// all surviving mice share a single subway; stale `GhostCat`s (not seen for 5s) are pruned.
    public func checkGameState() {
        for subway in subways {
            let miceInSub = mice.filter { $0.subway == subway.id }
            if let result = subway.resolveVotingIfDone(miceHere: miceInSub) {
                let miceIds = miceInSub.map { $0.id }
                logger.info("voteResult in \(subway.id) result \(result) for mice \(miceIds)")
                gameDelegate?.voteResult(result, for: miceIds)
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

            for subway in subways {
                subway.pruneStaleGhostCats()
            }
    }

    /// Postcondition: every mouse's surface time is finalized and `winner` is set - the cat
    /// with the most catches if all mice were caught, otherwise the mouse with the most time
    /// on the surface.
    public func endGame() {
        for mouse in mice {
            mouse.finalizeTimeOnSurface()
        }
        
        logger.info("setting winner")
        if caughtMice == mice.count {
            winner = cats.max(by: { $0.caught.count < $1.caught.count })
        } else {
            winner = mice.max(by: { $0.totalTimeOnSurface < $1.totalTimeOnSurface })         
        }
    }

    /// Precondition: `gameReady` (not enforced here).
    /// Postcondition: subways/exits are generated, every player has an initial placement, and
    /// `endTime` is `Game.duration` from now.
    public func startGame() {
        logger.info("starting game")
        createSubways()

        positionPlayers()

        self.endTime = Date() + Game.duration
    }

    /// Postcondition: the player with this id is removed from `players` if present. No error
    /// if the id is unknown - leaving is always safe to request, by design.
    public func leaveGame(player: Int64) {
        logger.info("removing player \(player)")
        players.removeAll(where: { $0.id == player })
    }

    func createSubways() {
        let numberOfExits = Int64(cats.count * 3)
        var numberOfExitsLeft = numberOfExits
        var id: Subway.ID = 0
        var totalExits = 0

        while numberOfExitsLeft > 1 {
            let exitsForSubway = Int64.random(in: 1...numberOfExitsLeft / 2)
            let subway = Subway(id: id)

            for exit_id in 0...exitsForSubway {
                subway.addExit(
                        Exit(
                            id: Int64((id * numberOfExits) + exit_id),
                            position: .random
                            ) // to have unique ids for each hole, id*numberOfExits is the offset for the subway, hole id is the offset for the hole in the subway
                )
            }
            totalExits += subway.exits.count

            subways.append(subway)

            numberOfExitsLeft -= exitsForSubway
            id += 1
        }

        logger.info("created \(subways.count) subways with \(totalExits) exits")
    }

    func positionPlayers() {
        let numberOfSubways = Int64(subways.count)
        logger.info("position players")
        for player in players {
            player.initialPlacement(subwayCount: numberOfSubways)
        }
    }


    /// Precondition: `player` must be the id of a current `Cat` or `Mouse`, otherwise throws
    /// `GameError.playerNotExisting`.
    /// Postcondition: the player's position advances by `direction`, clamped to the field; if
    /// it is a `Cat`, any now-adjacent, not-yet-caught, surface-level mice become caught and
    /// `gameDelegate?.gotCaught` fires once per newly caught mouse.
    public func move(player: Int64, _ direction: Direction) throws {
        guard let player: (any Player) = cats.first(where: { $0.id == player }) ?? mice.first(where: { $0.id == player }) else {
            throw GameError.playerNotExisting
        }


        let newPosition = direction
                .newPosition(position: player.position, with: player.speed)
                .inRange()

        logger.info("player \(player) moved \(direction.rawValue) to \(newPosition)")

        player.move(to: newPosition)

        let caughtIds = player.catchNearbyMice(from: mice.filter { $0.subway == nil })
        for mouseId in caughtIds {
            caughtMice += 1
            logger.info("mouse \(mouseId) caught by \(player.id)")
            gameDelegate?.gotCaught(mouseId)
        }
    }
}

//MARK: subway
extension Game { 
    /// Preconditions: `subway` must be a known `Subway.ID` (else throws
    /// `GameError.noHoleFoundForID`); `mouse` must be a known `Mouse.ID` (else throws
    /// `GameError.noMouseFoundForID`).
    /// Postcondition: delegates to `Subway.refreshGhostCats` and sets the mouse's `subway`.
    public func enter(subway: Int64, mouse: Int64) throws {
        guard let subway = subways.first(where: { $0.id == subway }) else {
            throw GameError.noHoleFoundForID
        }
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }

        subway.refreshGhostCats(from: cats)

        mouse.enterSubway(subway.id)

        logger.info("mouse \(mouse) entered sub \(subway)")
    }

    /// Precondition: `mouse` must be a known `Mouse.ID` currently assigned to a subway (else
    /// throws `GameError.noMouseFoundForID` / `GameError.mouseNotInSubway`).
    /// Postcondition: delegates to that `Subway.leave`, which validates `exit` belongs to it
    /// and reassigns or ends a `Voting` this mouse was managing.
    public func leave(exit: Int64, mouse: Int64) throws {
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }
        guard let subwayId = mouse.subway, let subway = subways.first(where: { $0.id == subwayId }) else {
            throw GameError.mouseNotInSubway
        }

        try subway.leave(
            mouse: mouse,
            exitId: exit,
            remainingMice: mice.filter { $0.id != mouse.id && $0.subway == subwayId }
        )

        logger.info("mouse \(mouse) left sub \(subwayId) via exit \(exit)")
    }
}

//MARK: Voting
extension Game {
    /// Precondition: `manager` must be a known `Mouse.ID` currently assigned to a subway (else
    /// throws `GameError.noMouseFoundForID` / `GameError.mouseNotInSubway`).
    /// Postcondition: delegates to `Subway.startVoting`.
    public func startVoting(manager: Int64) throws {
        guard let mouse = mice.first(where: { $0.id == manager }) else {
            throw GameError.noMouseFoundForID
        }
        guard let subwayId = mouse.subway, let subway = subways.first(where: { $0.id == subwayId }) else {
            throw GameError.mouseNotInSubway
        }

        try subway.startVoting(manager: mouse)
    }

    /// Precondition: `mouse` must be a known `Mouse.ID` currently assigned to a subway (else
    /// throws `GameError.noMouseFoundForID` / `GameError.mouseNotInSubway`).
    /// Postcondition: delegates to `Subway.vote`, scoped to the mice currently in that subway.
    public func vote(subway: Int64, mouse: Int64) throws {
        guard let mouse = mice.first(where: { $0.id == mouse }) else {
            throw GameError.noMouseFoundForID
        }
        guard let subwayId = mouse.subway, let currentSubway = subways.first(where: { $0.id == subwayId }) else {
            throw GameError.mouseNotInSubway
        }

        try currentSubway.vote(mouse: mouse, for: subway, miceHere: mice.filter { $0.subway == subwayId })
    }

    /// Precondition: `subway` must be a known `Subway.ID` and `manager` a known `Mouse.ID`
    /// (else throws `GameError.votingNotExists` / `GameError.noMouseFoundForID`).
    /// Postcondition: delegates to `Subway.endVoting`.
    public func endVoting(subway: Int64, manager: Int64) throws {
        guard let subway = subways.first(where: { $0.id == subway }) else {
            throw GameError.votingNotExists
        }
        guard let mouse = mice.first(where: { $0.id == manager }) else {
            throw GameError.noMouseFoundForID
        }

        try subway.endVoting(manager: mouse)
    }
}
