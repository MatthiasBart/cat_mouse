import Vapor
struct GameClient {
  let id: UUID = UUID()
  let socket: WebSocket
  let role: Role
  let gameCode: String
  let playerId: Int64
}
