//
// GameSocketController.swift
// Holds the WS connection and message parsing logic
//

import Vapor

protocol GameSocketControllerProtocol {
  /// Creates a player/client for the request and initializes the connection
  func connect(req: Request, ws: WebSocket)

  /// Handles client messages of the given type for the given player
  func handleMessage(type: ClientMessageType, data: Data, playerID: UUID, req: Request) throws
}

struct GameSocketController: RouteCollection {
  let service: ClientsService

  init(clientsService: ClientsService) {
    self.service = clientsService
  }

  func boot(routes: any RoutesBuilder) throws {
    routes.webSocket(":code", "ws") { req, ws in
      self.connect(req: req, ws: ws)
    }
  }
}

extension GameSocketController: GameSocketControllerProtocol {
  func connect(req: Request, ws: WebSocket) {
    // TODO: get role from session
    let client = GameClient(socket: ws, role: .cat)

    let storeTask = Task {
      await service.add(client)
    }

    req.logger.notice("Player \(client.role) \(client.id) connected.")

    ws.onText { ws, text in
      self.onText(req, ws, client.id, text)
    }

    ws.onClose.whenComplete { _ in
      req.logger.notice("Client \(client.id) disconnected.")
      Task {
        storeTask.cancel()
        await service.remove(with: client.id)
      }
    }
  }

  func handleMessage(type: ClientMessageType, data: Data, playerID: UUID, req: Request)
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
          await service.send(GameUpdate(seq: 1, time: 1000), to: playerID)
        }
      }
    } catch {
      req.logger.debug("Failed to decode message \(error)")
      throw GameError.invalidJSON
    }
  }

  // MARK: - Utilities

  private func onText(_ req: Request, _ ws: WebSocket, _ playerID: UUID, _ text: String) {
    do {
      guard let data = text.data(using: .utf8) else {
        throw GameError.invalidJSON
      }

      let decoder = JSONDecoder()

      struct Peek: Codable { let type: ClientMessageType }
      guard let peek = try? decoder.decode(Peek.self, from: data) else {
        throw GameError.invalidType
      }

      try self.handleMessage(type: peek.type, data: data, playerID: playerID, req: req)
    } catch let error as GameError {
      req.logger.error("Game Error (\(playerID)): \(error)")
      Task { await service.sendError(error, to: playerID) }

    } catch {
      req.logger.error("Unexpected error: \(error)")
      Task { await service.sendError(.unknown, to: playerID) }
    }
  }
}
