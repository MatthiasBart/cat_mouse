//
// WebSocketController.swift
// Holds the WS connection and message parsing logic
//

import Vapor

class WebSocketController: RouteCollection {
  let roomsService: RoomsService

  init(roomsService: RoomsService) {
    self.roomsService = roomsService
  }

  func boot(routes: any RoutesBuilder) throws {
    let protectedRoutes = routes.grouped(PlayerSessionGuardMiddleware())

    protectedRoutes.webSocket("games", ":code", "ws") { [weak self] req, ws in
      try? await self?.connect(req: req, ws: ws)
    }
  }
}

extension WebSocketController {
  func connect(req: Request, ws: WebSocket) async throws {
    guard let playerInfo = PlayerInfo(from: req.session) else {
      req.logger.info("Connection rejected: Missing or invalid session.")
      try await ws.send("Connection rejected: Missing or invalid session.")
      _ = try? await ws.close(code: .policyViolation)
      return
    }

    req.logger.info("Player \(playerInfo.name) ws connection.")

    await roomsService.setWS(ws, for: playerInfo.id, in: playerInfo.roomCode)

    ws.onClose.whenComplete { [weak self] _ in
      Task { await self?.roomsService.setWS(nil, for: playerInfo.id, in: playerInfo.roomCode) }
    }
  }
}
