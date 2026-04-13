class Mouse: Player {
    var id: Int64 = -1
    var name: String = "" 
    var subway: Subway.ID? = nil
    var position: Position = .base
}

extension Mouse {
    func isNear(_ exit: Exit) -> Bool {
        self.position.isNear(exit.position)
    }
}
