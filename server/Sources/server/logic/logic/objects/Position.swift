struct Position: Encodable {
    var x: Int64
    var y: Int64
}

extension Position {
    static let MAX_X: Int64 = 600
    static let MAX_Y: Int64 = 450

    static var base: Position {
        Position(x: 0, y: 0)
    }

    static var random: Position {
        Position(x: Int64.random(in: 0...MAX_X), y: Int64.random(in: 0...MAX_Y))
    }

    func isNear(_ position: Self, distance: Int = 20) -> Bool {
        let distanceX = Int64(distance)
        let distanceY = Int64(distance)

        return ((position.x - distanceX) < self.x && (position.x + distanceX) > self.x) &&
        ((position.y - distanceY) < self.y && (position.y + distanceY) > self.y)
    }

    func inRange() -> Position { 
        Position(
                x: max(0, min(Position.MAX_X, self.x)),
                y: max(0, min(Position.MAX_Y, self.y))
        )
    }
}
