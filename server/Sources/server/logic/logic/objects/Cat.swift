import Foundation

public class Cat: Player {
    public var id: Int64 = -1
    var name: String = ""
    var position: Position = .base
    private(set) var caught: [Mouse.ID] = []
    private var type = "live"
    let speed: Int64 = 15

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

class GhostCat: Cat {
    private var type = "ghost"
    var lastSeen: Date = Date()

    init(from cat: Cat) {
        super.init()
        self.id = cat.id
        self.name = cat.name
        self.position = cat.position
        self.lastSeen = Date()
    }
}
