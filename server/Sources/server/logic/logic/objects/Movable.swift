/// Abstraction over "can change its position" via a single, explicit operation.
protocol Movable: Positionable {
    /// Precondition: `position` must already be within the field's bounds.
    /// Postcondition: afterwards `position == position` (the argument).
    func move(to position: Position)
}
