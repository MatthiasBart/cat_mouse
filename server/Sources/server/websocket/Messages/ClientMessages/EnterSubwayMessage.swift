/// Delegates to `Game.enter`; inherits that method's preconditions and `GameError`s.
struct EnterSubwayMessage: ClientMessage {
    var type: ClientMessageType { .enterSubway }
    var subwayId: Int64

    func execute(on game: Game, by player: Int64) throws {
        try game.enter(subway: subwayId, mouse: player)
    }
}
