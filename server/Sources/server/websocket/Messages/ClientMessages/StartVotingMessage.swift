/// Delegates to `Game.startVoting`; inherits that method's preconditions and `GameError`s.
struct StartVotingMessage: ClientMessage {
    var type: ClientMessageType { .startVote }

    func execute(on game: Game, by player: Int64) throws {
        try game.startVoting(manager: player)
    }
}
