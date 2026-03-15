class Subway {
    let entryA: Hole
    let entryB: Hole

    init(entryA: Hole = Hole(position: .base), entryB: Hole = Hole(position: .base)) { 
        self.entryA = entryA
        self.entryB = entryB
    }
}

class Hole: Positionable {
    var position: Position

    init(position: Position = .init(x: 0, y: 0)) {
        self.position = position
    }
}
