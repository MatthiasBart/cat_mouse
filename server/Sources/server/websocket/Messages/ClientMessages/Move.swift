struct MoveMessage: ClientMessage {
  var type: ClientMessageType { .move }
  var direction: Direction

  enum Direction: String, Decodable {
    case up = "UP"
    case down = "DOWN"
    case left = "LEFT"
    case right = "RIGHT"
  }
}
