import Vapor

// for multi-cast
enum Group {
  case mouse
  case cat
}

struct GameClient {
  let id: UUID = UUID()
  let socket: WebSocket
  let role: Group
}
