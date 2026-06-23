import Foundation
import Logging

private let logger = Logger(label: "Subway")

/// A single exit point belonging to exactly one `Subway`. Plain, immutable data - it does not
/// know which subway it belongs to; that is the owning `Subway`'s responsibility, not its own.
struct Exit: Positionable {
    let id: Int64
    let position: Position
}

/// Owns everything that only makes sense in the context of one subway: its exits, the
/// `GhostCat`s mice inside it currently see, and the (at most one) running `Voting`.
///
/// Invariant: `voting` is non-`nil` exactly while a vote is running or has run out but not yet
/// resolved by `resolveVotingIfDone()`.
class Subway: Identifiable {
    let id: Int64
    private(set) var exits: [Exit] = []
    private(set) var ghostCats: [GhostCat] = []
    private(set) var voting: Voting?

    init(id: Int64) {
        self.id = id
    }

    /// Postcondition: `exits` contains `exit`.
    func addExit(_ exit: Exit) {
        exits.append(exit)
    }
}

extension Subway {
    /// Postcondition: `ghostCats` equals a snapshot of `cats` taken at this moment.
    func refreshGhostCats(from cats: [Cat]) {
        ghostCats = cats.map { GhostCat(from: $0) }
    }

    /// Postcondition: `ghostCats` no longer contains entries older than 5 seconds.
    func pruneStaleGhostCats() {
        ghostCats = ghostCats.filter { $0.lastSeen > Date().addingTimeInterval(-5) }
    }
}

extension Subway {
    /// Precondition: `exitId` must be one of `exits` (else throws `GameError.noHoleFoundForID`).
    /// Postcondition: `mouse.subway == nil`; if `mouse` was the voting's manager, the manager
    /// is `remainingMice.first`, or `voting.endTime` is now if `remainingMice` is empty.
    func leave(mouse: Mouse, exitId: Int64, remainingMice: [Mouse]) throws {
        guard let exit = exits.first(where: { $0.id == exitId }) else {
            throw GameError.noHoleFoundForID
        }

        mouse.exit(via: exit)

        guard let voting, voting.manager.id == mouse.id else { return }
        if let newManager = remainingMice.first {
            voting.manager = newManager
            logger.info("new manager \(newManager.id) for voting in sub \(id)")
        } else {
            voting.endTime = Date()
            logger.info("voting ended since left mouse was only one")
        }
    }
}

extension Subway {
    /// Precondition: this subway must not already have a still-running `Voting` (else throws
    /// `GameError.votingAlreadyExists`).
    /// Postcondition: `voting` is non-`nil`; `voting.manager == manager`; `voting.endTime` is
    /// `Voting.duration` from now.
    func startVoting(manager: Mouse) throws {
        if let voting, !voting.isRunOut() {
            throw GameError.votingAlreadyExists
        }

        voting = Voting(endTime: Date() + Voting.duration, manager: manager)
        logger.info("voting started by \(manager.id) in sub \(id)")
    }

    /// Preconditions: this subway must have an active `Voting` (else throws
    /// `GameError.votingNotExists`) that has not run out (else throws `GameError.votingNotValid`).
    /// Postcondition: `voting.votes[mouse.id] == targetSubway`, overwriting any previous entry
    /// for `mouse`; if every mouse in `miceHere` has now voted, `voting.endTime` is now.
    func vote(mouse: Mouse, for targetSubway: Int64, miceHere: [Mouse]) throws {
        guard let voting else {
            throw GameError.votingNotExists
        }
        guard !voting.isRunOut() else {
            throw GameError.votingNotValid
        }

        voting.votes[mouse.id] = targetSubway
        logger.info("\(mouse.id) voted for \(targetSubway)")

        if miceHere.allSatisfy({ voting.votes.keys.contains($0.id) }) {
            logger.info("all mice in sub \(id) voted for sub \(targetSubway)")
            voting.endTime = Date()
        }
    }

    /// Preconditions: this subway must have an active `Voting` (else throws
    /// `GameError.votingNotExists`); `manager` must be that voting's manager (else throws
    /// `GameError.notPermittedToEndVoting`).
    /// Postcondition: `voting.endTime` is now.
    func endVoting(manager: Mouse) throws {
        guard let voting else {
            throw GameError.votingNotExists
        }
        guard manager.id == voting.manager.id else {
            throw GameError.notPermittedToEndVoting
        }

        voting.endTime = Date() //TODO add way to flag as canceled
        logger.info("voting in sub \(id) got canceled by \(manager.id)")
    }

    /// Postcondition: if `voting` was non-`nil` and either run out or every mouse in `miceHere`
    /// had voted, `voting` is now `nil` and the result is the subway with the most votes, or
    /// `nil` if there were no votes; otherwise nothing changes and the result is `nil`.
    func resolveVotingIfDone(miceHere: [Mouse]) -> Subway.ID? {
        guard let voting else { return nil }
        guard voting.isRunOut() || miceHere.count == voting.votes.count else { return nil }

        let result = voting.highestVotedSub()
        self.voting = nil

        return result
    }
}
