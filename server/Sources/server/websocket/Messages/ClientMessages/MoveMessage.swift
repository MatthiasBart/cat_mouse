struct MoveMessage: ClientMessage {
  var type: ClientMessageType { .move }
  var direction: Direction
}
