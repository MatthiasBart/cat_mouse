/// Delegates to `Game.leaveGame`, which has no preconditions and never throws.
struct LeaveGameMessage: ClientMessage {
    var type: ClientMessageType { .leaveGame }

    func execute(on game: Game, by player: Int64) throws {
        game.leaveGame(player: player)
    }
}
