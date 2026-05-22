struct VoteResultMessage: ServerMessage {
    let type: ServerMessageType = .voteResult
    var win_subway: Int64
}
