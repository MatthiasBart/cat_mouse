enum ClientMessageType: String, Codable {
  case move = "MOVE"
}

protocol ClientMessage: Decodable {
  var type: ClientMessageType { get }
}

struct AnyClientMessage: ClientMessage {
  var type: ClientMessageType
}

enum ServerMessageType: String, Codable {
  case connectionInit = "CONNECTION_INIT"
  case playerJoined = "PLAYER_JOINED"
  case gameInit = "GAME_INIT"
  case gameUpdate = "GAME_UPDATE"
  case gameOver = "GAME_OVER"
  case error = "ERROR"
}

protocol ServerMessage: Encodable {
  var type: ServerMessageType { get }
}

import Vapor 

extension WebSocket {
  func send(_ message: ServerMessage) async throws {
    let encoder = JSONEncoder()
    let collection = try encoder.encode(message)
    try await self.send(String(data: Data, encoding: .utf8))
  }

  func onMessage(_ callback: @escaping @Sendable (WebSocket, ClientMessage) -> ()) {
    let decoder = JSONDecoder()
    onText({ ws, text in
      guard
        let data = text.data(using: .utf8),
        let anyMessage = try? decoder.decode(AnyClientMessage.self, from: data)
      else {
        let error = ServerError.invalidMessage
        let errorMsg = ErrorMessage(
          code: error.rawValue,
          message: error.localizedDescription
        )
        send(errorMsg)
      }

      switch anyMessage.type {
        case .move:
          let moveMessage = try? decoder.decode(MoveMessage.self, from: text.data(using: .utf8))
          callback(ws, moveMessage)
      }
    })
  }
}