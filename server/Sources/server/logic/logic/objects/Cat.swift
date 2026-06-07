import Foundation

class Cat: Player {
    let id: Int64
    let name: String
    var position: Position = .base
    private(set) var caught: [Mouse.ID] = []
    let speed: Int64 = 15

    init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }

    var role: Role { .cat }

    func initialPlacement(subwayCount: Int64) {
        position = .random
    }

    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID] {
        var caughtIds: [Mouse.ID] = []
        for mouse in mice where mouse.caught == nil && position.isNear(mouse.position) {
            caught.append(mouse.id)
            mouse.beCaught(by: id)
            caughtIds.append(mouse.id)
        }
        return caughtIds
    }

    func toDTO() -> PlayerDTO {
        PlayerDTO(id: id, name: name, role: "cat", subway: nil, position: position, caught: Int64(caught.count))
    }

}

class GhostCat: Positionable {
    let id: Int64
    let name: String
    var position: Position
    var lastSeen: Date

    init(from cat: Cat) {
        self.id = cat.id
        self.name = cat.name
        self.position = cat.position
        self.lastSeen = Date()
    }
}
