import Vapor

// for multi-cast
enum Role: Codable, CaseIterable {
  case mouse
  case cat

  static var random: Role {
    // Force-unwrapping is perfectly safe here because we know the enum has defined cases.
    return Self.allCases.randomElement()!
  }
}

struct GameClient {
  let id: UUID = UUID()
  let socket: WebSocket
  let role: Role
}
