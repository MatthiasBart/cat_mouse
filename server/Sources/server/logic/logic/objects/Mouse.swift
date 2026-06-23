import Foundation

/// Concrete `Player` fulfilling the evading role: tracks subway/surface state and how long
/// it has spent on the surface (used to determine the winning mouse).
///
/// History constraint: `totalTimeOnSurface` only ever grows.
class Mouse: Player {
    let id: Int64
    let name: String
    private(set) var subway: Subway.ID? = nil
    private(set) var position: Position = .base
    private(set) var caught: Cat.ID? = nil
    private(set) var totalTimeOnSurface: TimeInterval = 0
    private(set) var lastExit: Date = Date()
    let speed: Int64 = 20

    init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }

    var role: Role { .mouse }

    func move(to position: Position) {
        self.position = position
    }

    /// Precondition: `subwayCount > 0`.
    /// Postcondition: `subway` equals a random id in `0..<subwayCount`.
    func initialPlacement(subwayCount: Int64) {
        subway = Int64.random(in: 0..<subwayCount)
    }

    /// Mice never catch other mice; always returns `[]`. This satisfies `Player`'s
    /// postcondition (no mouse is falsely claimed caught) without strengthening the
    /// precondition, so substitutability for `Player` still holds.
    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID] { [] }

    /// Postcondition: `subway == subwayId`; `totalTimeOnSurface` equals its previous value
    /// plus the time since `lastExit`.
    func enterSubway(_ subwayId: Subway.ID) {
        totalTimeOnSurface += lastExit.distance(to: Date())
        subway = subwayId
    }

    /// Precondition: `exitPoint` belongs to the subway this mouse is currently in.
    /// Postcondition: `subway == nil`; `position == exitPoint.position`; `lastExit` equals the
    /// time of this call.
    func exit(via exitPoint: Exit) {
        subway = nil
        position = exitPoint.position
        lastExit = Date()
    }

    /// Postcondition: `caught == catId`.
    /// History constraint: once set, `caught` is never cleared again.
    func beCaught(by catId: Cat.ID) {
        caught = catId
    }

    /// Precondition: intended to be called once, at game end.
    /// Postcondition: totalTimeOnSurface contains final total time on surface
    func finalizeTimeOnSurface() {
        if subway == nil {
            totalTimeOnSurface += lastExit.distance(to: Date())
        }
    }

}

extension Mouse {
    func isNear(_ exit: Exit) -> Bool {
        self.position.isNear(exit.position)
    }
}
