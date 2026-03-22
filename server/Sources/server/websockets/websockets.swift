import Vapor

func webSockets(_ manager: ClientManager, _ app: Application) throws {
  app.webSocket("game") { req, ws in
    let client = GameClient(socket: ws, role: .cat)

    let storeClientTask = Task {
      await manager.add(client)
    }

    req.logger.notice("Player \(client.role) \(client.id) connected.")

    ws.onText { ws, text in
      req.logger.debug("Received from \(client.id): \(text)")
      do {
        guard let data = text.data(using: .utf8) else {
          throw GameError.malformedData
        }

        let decoder = JSONDecoder()

        struct MessageTypePeek: Codable { let type: MessageType }
        guard let peek = try? decoder.decode(MessageTypePeek.self, from: data) else {
          throw GameError.unknownType
        }

        handleMessage(type: peek.type, data: data, playerID: client.id)
      } catch let error as GameError {
        let response = ErrorMessage(code: error.rawValue, message: error.localizedDescription)
        if let json = try? JSONEncoder().encode(response),
          let jsonString = String(data: json, encoding: .utf8)
        {
          ws.send(jsonString)
        }
      } catch {
        print("unkown error")
      }
    }

    ws.onClose.whenComplete { _ in
      req.logger.notice("Client \(client.id) disconnected.")
      Task {
        storeClientTask.cancel()  // cancel the task in case it has not run yet
        await manager.remove(with: client.id)
      }
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
  case .error:
    print("error: \(data)")
  }
}
