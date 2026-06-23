enum ClientMessageType: String, Codable {
  case move = "MOVE"
  case leaveSubway = "LEAVE_SUBWAY"
  case enterSubway = "ENTER_SUBWAY"
  case startVote = "START_VOTE"
  case leaveGame = "LEAVE_GAME"
  case voteDecision = "VOTE_DECISION"

}

/// Command-style abstraction (single dispatch on the message's own type - see slide 5's
/// "visitor pattern" for how this simulates dispatching on a second type, the `Game`
/// operation invoked, without needing true multiple dispatch).
///
/// Contract: `execute` may throw any `GameError` that the `Game` operation it delegates to
/// can throw, and must not throw anything beyond that (s4: a conformer must not throw more
/// exceptions than the behaviour it stands in for). Conformers must not swallow such errors.
protocol ClientMessage: Decodable, Sendable {
  var type: ClientMessageType { get }
  func execute(on game: Game, by player: Int64) throws
}

/// Placeholder conformer used only to decode an unrecognized `type`; intentionally a no-op,
/// which is still a valid (if useless) fulfillment of `ClientMessage`'s contract.
struct AnyClientMessage: ClientMessage {
  var type: ClientMessageType
  func execute(on game: Game, by player: Int64) throws {}
}

enum ServerMessageType: String, Codable {
  case connectionInit = "CONNECTION_INIT"
  case playerJoined = "PLAYER_JOINED"
  case gameInit = "GAME_INIT"
  case mouseCaught = "CAUGHT"
  case voteResult = "VOTE_RESULT"
  case gameUpdate = "GAME_UPDATE"
  case gameEnded = "GAME_ENDED"
  case error = "ERROR"
}

/// Marker abstraction for outbound messages. Contract is purely structural (`Encodable` plus
/// a `type` tag the client discriminates on) - no behavioural obligations.
protocol ServerMessage: Encodable, Sendable {
  var type: ServerMessageType { get }
}

