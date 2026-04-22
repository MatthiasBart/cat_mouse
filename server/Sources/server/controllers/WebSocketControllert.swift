//
// WebSocketController.swift
// Holds the WS connection and message parsing logic
//

import Vapor

class WebSocketController: RouteCollection {
  let clientService: ClientsService
  let gamesService: GamesService
  var wsStore: [Int64: WebSocket] = [:]

  init(clientsService: ClientsService, gamesService: GamesService) {
    self.clientService = clientsService
    self.gamesService = gamesService
  }

  func boot(routes: any RoutesBuilder) throws {
    let protectedRoutes = routes.grouped(PlayerSessionGuardMiddleware())

    protectedRoutes.webSocket("games", ":code", "ws") { req, ws in
      self.connect(req: req, ws: ws)
    }
  }
}

extension WebSocketController {
  func connect(req: Request, ws: WebSocket) {
    guard let info = PlayerInfo(from: req.session) else {
      req.logger.info("Connection rejected: Missing or invalid session.")
      ws.send("Connection rejected: Missing or invalid session.")
      _ = ws.close(code: .policyViolation)
      return
    }

    req.logger.info("Player \(info.playerName) ws connection.")

    wsStore[info.playerId] = ws

    ws.onMessage({ ws, message in
      if let move = message as? MoveMessage {
          
      } 
    })  

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
}
