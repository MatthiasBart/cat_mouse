enum Direction: Decodable {
    case up
    case down
    case left
    case right

    func newPosition(position: Position) -> Position {
        var position = position
        let speed: Int64 = 20
        switch self {
            case .up: 
                position.y = position.y + speed
                return position
            case .down: 
                position.y = position.y - speed
                return position
            case .left: 
                position.x = position.x - speed
                return position
            case .right:
                position.x = position.x + speed
                return position
        }
    }
}
