class Subway: Identifiable {
    let id: Int64
    let exits: [Hole]

    init(id: Int64, exits: [Hole] = []) {
        self.id = id
        self.exits = exits
    }
}

class Hole: Positionable {
    var position: Position

    init(position: Position = .base) {
        self.position = position
    }
}
