struct VoteResultMessage: ServerMessage {
    var type: ServerMessageType { .voteResult }
    var win_subway: Int64
}