import Foundation

/// Abstraction over a participant in a game: gives every player an identity, movement, and
/// role-specific behaviour (initial placement, catching), regardless of whether it's a `Cat`
/// or `Mouse`.
///
/// History constraint: `id` is assigned once at construction and never changes.
protocol Player: AnyObject, Identifiable, Movable {
    var id: Int64 { get }
    var name: String { get }
    var speed: Int64 { get }
    var role: Role { get }

    /// Precondition: `subwayCount > 0`.
    /// Postcondition: the player has a valid starting position or subway assignment.
    func initialPlacement(subwayCount: Int64)

    /// Postcondition: every returned `Mouse.ID` is now caught. A conformer with no catching
    /// behaviour must return `[]` rather than claim a catch it did not perform.
    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID]
}

/// A player's view of itself (sent only to that player).
class PlayerDTO: Encodable {
    var id: Int64
    var name: String
    var role: String
    var subway: Int64?
    var position: Position
    var caught: Int64?

    init(
        id: Int64,
        name: String,
        role: String,
        subway: Int64?,
        position: Position,
        caught: Int64?
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.subway = subway
        self.position = position
        self.caught = caught
    }
}

extension PlayerDTO {
    convenience init(cat: Cat) {
        self.init(id: cat.id, name: cat.name, role: "cat", subway: nil, position: cat.position, caught: Int64(cat.caught.count))
    }

    convenience init(mouse: Mouse) {
        self.init(id: mouse.id, name: mouse.name, role: "mouse", subway: mouse.subway, position: mouse.position, caught: mouse.caught)
    }
}
