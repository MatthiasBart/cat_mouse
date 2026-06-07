import Foundation

class Mouse: Player {
    var id: Int64 = -1
    var name: String = ""
    var subway: Subway.ID? = nil
    var position: Position = .base
    var caught: Cat.ID? = nil
    var totalTimeOnSurface: TimeInterval = 0
    var lastExit: Date = Date()
    let speed: Int64 = 20

    var role: Role { .mouse }

    func initialPlacement(subwayCount: Int64) {
        subway = Int64.random(in: 0..<subwayCount)
    }

    func catchNearbyMice(from mice: [Mouse]) -> [Mouse.ID] { [] }

    func toDTO() -> PlayerDTO {
        PlayerDTO(id: id, name: name, role: "mouse", subway: subway, position: position, caught: caught ?? -1)
    }

}

extension Mouse {
    func isNear(_ exit: Exit) -> Bool {
        self.position.isNear(exit.position)
    }
}
