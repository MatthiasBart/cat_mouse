/// Delegates to `Game.leave`; inherits that method's preconditions and `GameError`s.
struct LeaveSubwayMessage: ClientMessage {
    var type: ClientMessageType { .leaveSubway }
    var exitId: Int64

    func execute(on game: Game, by player: Int64) throws {
        try game.leave(exit: exitId, mouse: player)
    }
}
