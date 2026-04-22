struct LeaveGameMessage: ClientMessage {
    var type: ClientMessageType { .leaveGame }
}