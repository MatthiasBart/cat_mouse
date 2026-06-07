struct StartVotingMessage: ClientMessage {
    var type: ClientMessageType { .startVote }

    func execute(on game: Game, by player: Int64) throws {
        try game.startVoting(manager: player)
    }
}
