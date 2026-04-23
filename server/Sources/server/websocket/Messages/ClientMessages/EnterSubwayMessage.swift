struct EnterSubwayMessage: ClientMessage {
    var type: ClientMessageType { .enterSubway }
    var subwayId: Int64
}