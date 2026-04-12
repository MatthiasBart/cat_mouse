protocol Movable: AnyObject, Positionable { 
    func move(to position: Position)
    func move(x: Int64, y: Int64)
}

extension Movable {
    func move(to position: Position) {
        self.position = position
    }

    func move(x: Int64, y: Int64) {
        let newPosition = Position(
            x: position.x + x,
            y: position.y + y
        )

        move(to: newPosition)
    }
}
