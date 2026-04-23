struct CaughtMessage: ServerMessage { 
    var type: ServerMessageType { .mouseCaught }
}