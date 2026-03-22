class Subway {
    let entryA: Hole
    let entryB: Hole

    init(entryA: Hole = Hole(), entryB: Hole = Hole()) { 
        self.entryA = entryA
        self.entryB = entryB
    }
}

class Hole: Positionable {
    var position: Position

    init(position: Position = .base) {
        self.position = position
    }
}
