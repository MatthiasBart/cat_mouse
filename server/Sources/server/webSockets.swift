import Vapor

func webSockets(_ app: Application) throws {
  app.webSocket("game") { req, ws in
    let playerID = UUID()
    req.logger.debug("Player \(playerID) connected via Text Frame")
    req.logger.debug("\(playerID) request: \(req)")
    req.logger.debug("\(playerID) ws: \(ws)")

    // TODO: change to onBinary?
    ws.onText { ws, text in
      guard let data = text.data(using: .utf8) else {
        req.logger.error("Could not convert text to UTF-8 data")
        return
      }

      let decoder = JSONDecoder()

      struct MessageTypePeek: Codable { let type: MessageType }

      guard let peek = try? decoder.decode(MessageTypePeek.self, from: data) else {
        req.logger.error("Error: Message missing 'type' field. Raw: \(text)")
        return
      }

      handleMessage(type: peek.type, data: data, playerID: playerID)
    }

    ws.onClose.whenComplete { result in
      // TODO: remove client from state
      req.logger.debug("ws closed: \(result)")
    }
  }
}

private func handleMessage(type: MessageType, data: Data, playerID: UUID) {
  let decoder = JSONDecoder()

  switch type {
  case .move:
    if let move = try? decoder.decode(Move.self, from: data) {
      print("MOVE: Player \(playerID) \(move.test)")
    }
  case .gameUpdate:
    print("Note: Clients usually don't send GAME_UPDATE to the server.")
  case .gameOver:
    print("Admin command: Triggering game end logic.")
  }
}
