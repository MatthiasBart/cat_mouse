protocol Movable: AnyObject, Positionable { //TODO: Use actor
    func move(to position: Position)
    func move(x: Int64, y: Int64)
}

extension Movable {
    func move(to position: Position) {
        self.position = position
    }

    func move(x: Int64, y: Int64) {
        let newPosition = Position(
            x: self.position.x + x,
            y: self.position.y + y
        )

        move(to: newPosition)
    }
}
