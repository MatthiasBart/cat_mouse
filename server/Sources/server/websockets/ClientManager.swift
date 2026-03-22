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
  func multicast(to group: Group, message: some ServerMessage) {
    storage.values
      .filter { clients in
        clients.role == group && !clients.socket.isClosed
      }
      .forEach { client in
        send(message, to: client.id)
      }
  }

  /// Sends a message to everyone
  func broadcastToAll(message: some ServerMessage) {
    storage.values.forEach { client in send(message, to: client.id) }
  }

  /// Sends a structured error to a specific player
  func sendError(_ error: GameError, to id: UUID) {
    let errorMsg = ErrorMessage(
      code: error.rawValue,
      message: error.localizedDescription
    )

    send(errorMsg, to: id)
  }

  func send(_ message: some ServerMessage, to id: UUID) {
    guard let client = storage[id], !client.socket.isClosed else { return }

    do {
      let data = try JSONEncoder().encode(message)
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
