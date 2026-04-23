struct LeaveSubwayMessage: ClientMessage {
    var type: ClientMessageType { .leaveSubway }
    var exitId: Int64
}