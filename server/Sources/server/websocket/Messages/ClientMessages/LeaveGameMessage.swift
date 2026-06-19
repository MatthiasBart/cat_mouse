struct LeaveGameMessage: ClientMessage {
    var type: ClientMessageType { .leaveGame }

    func execute(on game: Game, by player: Int64) throws {
        game.leaveGame(player: player)
    }
}
