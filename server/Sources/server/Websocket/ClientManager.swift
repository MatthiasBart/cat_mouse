import Vapor

actor ClientManager {
  private var storage: [UUID: GameClient] = [:]

  // Adds client to storage
  func add(_ client: GameClient) {
    storage[client.id] = client
  }

  /// Removes client with storage
  func remove(with id: UUID) {
    storage.removeValue(forKey: id)
  }

  /// Sends a message to a specific group (e.g., all Cats)
  func multicast(to group: Group, message: String) {
    storage.values
      .filter { clients in
        clients.role == group && !clients.socket.isClosed
      }
      .forEach { client in
        client.socket.send(message)
      }
  }

  /// Sends a message to everyone
  func broadcastToAll(message: String) {
    storage.values.forEach { $0.socket.send(message) }
  }
}
