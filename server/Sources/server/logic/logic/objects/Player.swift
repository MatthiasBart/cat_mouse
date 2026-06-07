import Foundation

protocol Player: AnyObject, Identifiable, Movable, Encodable {
    var id: Int64 { get }
    var name: String { get }
    var speed: Int64 { get }
    var role: Role { get }
    func initialPlacement(subwayCount: Int64)
    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID]
    func toDTO() -> PlayerDTO
}

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
