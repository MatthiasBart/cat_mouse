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
  let gamesService: GamesService

  init(clientsService: ClientsService, gamesService: GamesService) {
    self.service = clientsService
    self.gamesService = gamesService
  }

  func boot(routes: any RoutesBuilder) throws {
    let protectedRoutes = routes.grouped(PlayerSessionGuardMiddleware())

    protectedRoutes.webSocket("games", ":code", "ws") { req, ws in
      self.connect(req: req, ws: ws)
    }
  }
}

extension GameSocketController: GameSocketControllerProtocol {
  func connect(req: Request, ws: WebSocket) {
    guard let session = PlayerSession(req: req) else {
      req.logger.info("Connection rejected: Missing or invalid session.")
      ws.send("Connection rejected: Missing or invalid session.")
      _ = ws.close(code: .policyViolation)
      return
    }

    req.logger.info("Player \(session.playerName) ws connection.")

    let client = GameClient(
      socket: ws,
      role: session.role,
      gameCode: session.code,
      playerId: session.playerId
    )

    let storeTask = Task {
      await service.add(client)

      do {
        let metaData = try await gamesService.getGameMetaData(code: session.code)
        let players = metaData.players.map {
          ConnectionInit.PlayerInfo(
            playerId: $0.playerId,
            playerName: $0.playerName,
            role: $0.role,
            isCreator: $0.isCreator,
            isComputer: $0.isComputer
          )
        }

        await service.send(
          ConnectionInit(
            code: metaData.code,
            started: metaData.started,
            currentPlayerId: session.playerId,
            players: players
          ),
          to: client.id
        )

        if metaData.started {
          await service.send(GameInit(code: metaData.code, role: session.role), to: client.id)
        }
      } catch {
        req.logger.warning("Failed to send connection init for \(session.code): \(error)")
      }
    }

    req.logger.notice("Player \(client.role) \(client.id) connected.")

    ws.onText { ws, text in
      self.onText(req, ws, client.id, text)
    }

    ws.onClose.whenComplete { _ in
      req.logger.notice("Client \(client.id) disconnected.")
      Task {
        storeTask.cancel()
        await service.remove(client: client.id, in: client.gameCode)
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
