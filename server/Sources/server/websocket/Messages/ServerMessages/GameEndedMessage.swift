struct GameEndedMessage: ServerMessage { 
    var type: ServerMessageType { .gameEnded }
    var player: Player
    var totalTime: Int64

    struct Player: Encodable {
        var id: Int64
        var name: String
        var type: String
        var caught: Int64?
        var timeOnSurface: Int64?
    }
}