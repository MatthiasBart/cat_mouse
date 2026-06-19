struct MoveMessage: ClientMessage {
  var type: ClientMessageType { .move }
  var direction: Direction

  func execute(on game: Game, by player: Int64) throws {
    try game.move(player: player, direction)
  }
}
