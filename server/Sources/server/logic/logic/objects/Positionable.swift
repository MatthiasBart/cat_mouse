/// Abstraction over "has a place in the game world": anything with a location that other code
/// can read.
protocol Positionable {
    var position: Position { get }
}
