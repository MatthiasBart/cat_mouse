import Vapor

struct GameController: RouteCollection {
  let manager: ClientManager

  init(clientManager: ClientManager) {
    self.manager = clientManager
  }

  func boot(routes: any RoutesBuilder) throws {
    let game = routes.grouped("game")
    game.webSocket(onUpgrade: self.connect)
  }

  func connect(req: Request, ws: WebSocket) {
    // TODO: get role from session
    let client = GameClient(socket: ws, role: .cat)

    let storeTask = Task {
      await manager.add(client)
    }

    req.logger.notice("Player \(client.role) \(client.id) connected.")

    ws.onText { ws, text in
      self.onText(req, ws, client.id, text)
    }

    ws.onClose.whenComplete { _ in
      req.logger.notice("Client \(client.id) disconnected.")
      Task {
        storeTask.cancel()
        await manager.remove(with: client.id)
      }
    }
  }

  private func onText(_ req: Request, _ ws: WebSocket, _ playerID: UUID, _ text: String) {
    do {
      guard let data = text.data(using: .utf8) else {
        throw GameError.malformedJSON
      }

      let decoder = JSONDecoder()

      struct Peek: Codable { let type: ClientMessageType }
      guard let peek = try? decoder.decode(Peek.self, from: data) else {
        throw GameError.unknownType
      }

      try self.handleMessage(type: peek.type, data: data, playerID: playerID, req: req)
    } catch let error as GameError {
      req.logger.error("Game Logic Error (\(playerID)): \(error)")
      Task { await manager.sendError(error, to: playerID) }

    } catch {
      req.logger.error("Unexpected error: \(error)")
      Task { await manager.sendError(.unknown, to: playerID) }
    }
  }

  private func handleMessage(type: ClientMessageType, data: Data, playerID: UUID, req: Request)
    throws
  {
    let decoder = JSONDecoder()
    do {
      switch type {
      case .move:
        let move = try decoder.decode(Move.self, from: data)
        req.logger.debug("MOVE: \(playerID) -> \(move.test)")
        Task {
          // TODO: real values
          await manager.send(GameUpdate(seq: 1, time: 1000), to: playerID)
        }
      }
    } catch {
      req.logger.debug("Failed to decode message \(error)")
      throw GameError.malformedJSON
    }
  }
}
