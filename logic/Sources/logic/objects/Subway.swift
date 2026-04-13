class Subway: Identifiable {
    let id: Int64

    init(id: Int64) {
        self.id = id
    }
}

class Exit: Positionable {
    var id: Int64
    var position: Position
    var subway: Subway

    init(id: Int64, position: Position = .base, subway: Subway) {
        self.id = id
        self.position = position
        self.subway = subway
    }
}
