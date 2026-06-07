import Foundation

class Mouse: Player {
    let id: Int64
    let name: String
    private(set) var subway: Subway.ID? = nil
    var position: Position = .base
    private(set) var caught: Cat.ID? = nil
    private(set) var totalTimeOnSurface: TimeInterval = 0
    private(set) var lastExit: Date = Date()
    let speed: Int64 = 20

    init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }

    var role: Role { .mouse }

    func initialPlacement(subwayCount: Int64) {
        subway = Int64.random(in: 0..<subwayCount)
    }

    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID] { [] }

    func toDTO() -> PlayerDTO {
        PlayerDTO(id: id, name: name, role: "mouse", subway: subway, position: position, caught: caught)
    }

    func enterSubway(_ subwayId: Subway.ID) {
        totalTimeOnSurface += lastExit.distance(to: Date())
        subway = subwayId
    }

    func exit(via exitPoint: Exit) {
        guard subway == exitPoint.subway.id else { return }
        subway = nil
        position = exitPoint.position
        lastExit = Date()
    }

    func beCaught(by catId: Cat.ID) {
        caught = catId
    }

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
