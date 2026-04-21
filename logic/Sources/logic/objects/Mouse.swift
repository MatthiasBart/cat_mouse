import Foundation 

class Mouse: Player {
    var id: Int64 = -1
    var name: String = "" 
    var subway: Subway.ID? = nil
    var position: Position = .base
    var totalTimeOnSurface: TimeInterval = 0
    var lastExit: Date = Date()
}

extension Mouse {
    func isNear(_ exit: Exit) -> Bool {
        self.position.isNear(exit.position)
    }
}
