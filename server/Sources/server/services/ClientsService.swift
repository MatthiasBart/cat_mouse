import Vapor

actor ClientsService {
  // Game "rooms" to "Clients"
  // Maps game codes to clients. 
  // Clients are stored by their ID for fast access.
  private var storage: [String: [UUID: GameClient]] = [:]

  // Adds client to storage
  func add(_ client: GameClient) {
    var roomClients = storage[client.gameCode] ?? [:]
    roomClients[client.id] = client
    storage[client.gameCode] = roomClients
  }

  /// Removes client with storage
  func remove(client: UUID, in gameCode: String) {
    guard var roomClients = storage[gameCode] else {
      return
    }

    roomClients.removeValue(forKey: client)

    if roomClients.isEmpty {
      storage.removeValue(forKey: gameCode)
    } else {
      storage[gameCode] = roomClients
    }
  }

  /// Sends a message to all connected clients in one game room
  func broadcast(message: some ServerMessage, in gameCode: String) {
    guard let roomClients = storage[gameCode] else {
      return
    }

    roomClients.values
      .filter { !$0.socket.isClosed }
      .forEach { client in
        send(message, to: client.id)
      }
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
    guard let client = findClient(id: id), !client.socket.isClosed else { return }

    do {
      let data = try JSONEncoder().encode(message)
      if let jsonString = String(data: data, encoding: .utf8) {
        client.socket.send(jsonString)
      }
    } catch {
      print("Failed to encode error for client \(id): \(error)")
    }
  }

  // Disconnects all clients and removes them from storage
  func clean() async {
    for room in storage.values {
      for client in room.values {
        try? await client.socket.close()
      }
    }
    self.storage.removeAll()
  }

  private func findClient(id: UUID) -> GameClient? {
    for room in storage.values {
      if let client = room[id] {
        return client
      }
    }
    return nil
  }
}
