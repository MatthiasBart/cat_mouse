struct Position { 
    var x: Int64
    var y: Int64
}

extension Position {
    static var base: Position {
        Position(x: 0, y: 0)
    }
}

