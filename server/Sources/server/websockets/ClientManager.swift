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

  /// Sends a structured error to a specific player
  func sendError(_ error: GameError, to id: UUID) {
    guard let client = storage[id], !client.socket.isClosed else { return }

    let errorMsg = ErrorMessage(
      code: error.rawValue,
      message: error.localizedDescription
    )

    do {
      let data = try JSONEncoder().encode(errorMsg)
      if let jsonString = String(data: data, encoding: .utf8) {
        client.socket.send(jsonString)
      }
    } catch {
      // TODO: use app logger
      print("Failed to encode error for client \(id): \(error)")
    }
  }

  // Disconnects all clients and removes them from storage
  func clean() async {
    for client in storage.values {
      try? await client.socket.close()
    }
    self.storage.removeAll()
  }
}
