import Foundation

/// Concrete `Player` fulfilling the catching role: marks nearby, not-yet-caught,
/// surface-level mice as caught and records them in `caught`.
///
/// History constraint: `caught` only ever grows.
class Cat: Player {
    let id: Int64
    let name: String
    private(set) var position: Position = .base
    private(set) var caught: [Mouse.ID] = []
    let speed: Int64 = 15

    init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }

    var role: Role { .cat }

    func move(to position: Position) {
        self.position = position
    }

    /// Postcondition: `position` is a random point on the field. `subwayCount` is unused.
    func initialPlacement(subwayCount: Int64) {
        position = .random
    }

    /// Precondition: `mice` must already be filtered to surface-level mice - a mouse currently
    /// in a subway has no position comparable to this cat's and would be caught only by
    /// coincidence otherwise.
    /// Postcondition: the result contains all ids of mice caught by this cat; `caught` is
    /// increased by the number of mice caught; each caught mouse has `caught` set to this
    /// cat's `id`.
    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID] {
        var caughtIds: [Mouse.ID] = []
        for mouse in mice where mouse.caught == nil && position.isNear(mouse.position) {
            caught.append(mouse.id)
            mouse.beCaught(by: id)
            caughtIds.append(mouse.id)
        }
        return caughtIds
    }

}

/// Read-only snapshot of a `Cat`'s public appearance at one point in time, shown to mice
/// hiding in a subway. Deliberately *not* a subtype of `Cat`: it only needs `Positionable`,
/// and giving it `Cat`'s full (mutable, catching) interface would reintroduce exactly the
/// substitutability/covariance problems discussed for role-asymmetric methods (see slide 5
/// on covariant problems) - a `GhostCat` must never be usable wherever a `Cat` is expected.
/// Treat it as an unrelated value snapshot, constructed once from a `Cat` and never written
/// back to it.
class GhostCat: Positionable {
    let id: Int64
    let name: String
    let position: Position
    let lastSeen: Date

    init(from cat: Cat) {
        self.id = cat.id
        self.name = cat.name
        self.position = cat.position
        self.lastSeen = Date()
    }
}
