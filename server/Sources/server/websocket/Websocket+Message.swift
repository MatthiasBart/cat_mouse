import Vapor 

extension WebSocket {
  func send(_ message: any ServerMessage) async throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(message)
    guard let collection = String(data: data, encoding: .utf8) else {
        throw ServerError.invalidMessage
    }
    try await self.send(collection)
  }

  func onMessage(_ callback: @escaping @Sendable (WebSocket, any ClientMessage) async throws -> ()) {
    let decoder = JSONDecoder()
    onText({ ws, text in
      guard
        let data = text.data(using: .utf8),
        let anyMessage = try? decoder.decode(AnyClientMessage.self, from: data)
      else {
        try? await ws.send(ErrorMessage(.invalidMessage))
        return 
      }

    do {
      switch anyMessage.type {
        case .move:
                let moveMessage = try decoder.decode(MoveMessage.self, from: data)
                try await callback(ws, moveMessage)
      }
    } catch {
        try? await ws.send(ErrorMessage(.invalidMessage))
    }
    })
  }
}