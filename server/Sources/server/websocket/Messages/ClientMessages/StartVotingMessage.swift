struct StartVotingMessage: ClientMessage {
    var type: ClientMessageType { .startVote }
}