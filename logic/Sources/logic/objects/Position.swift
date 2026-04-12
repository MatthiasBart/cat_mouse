struct Position {
    var x: Int64
    var y: Int64
}

extension Position {
    static var base: Position {
        Position(x: 0, y: 0)
    }

    static var random: Position {
        Position(x: Int64.random(in: 0...600), y: Int64.random(in: 0...450))
    }
}
