struct LeaveSubwayMessage: ClientMessage {
    var type: ClientMessageType { .leaveSubway }
    var exitId: Int64

    func execute(on game: Game, by player: Int64) throws {
        try game.leave(exit: exitId, mouse: player)
    }
}
