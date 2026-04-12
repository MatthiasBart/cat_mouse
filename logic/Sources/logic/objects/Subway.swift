class Subway: Identifiable {
    let exits: [Hole]

    init(exits: [Hole] = []) {
        self.exits = exits
    }
}

class Hole: Positionable {
    var position: Position

    init(position: Position = .base) {
        self.position = position
    }
}
