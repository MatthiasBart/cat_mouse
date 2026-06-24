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
    let roomsService = self.roomsService

    protectedRoutes.webSocket("games", ":code", "ws") { req, ws in
      do {
        try await Self.connect(req: req, ws: ws, roomsService: roomsService)
      } catch {
        req.logger.report(error: error)
        _ = try? await ws.close(code: .unexpectedServerError)
      }
    }
  }
}

extension WebSocketController {
  static func connect(req: Request, ws: WebSocket, roomsService: RoomsService) async throws {
    guard let playerInfo = PlayerInfo(from: req.session) else {
      req.logger.info("Connection rejected: Missing or invalid session.")
      try await ws.send("Connection rejected: Missing or invalid session.")
      _ = try? await ws.close(code: .policyViolation)
      return
    }

    req.logger.info("Player \(playerInfo.name) ws connection.")

    await roomsService.setWS(ws, for: playerInfo.id, in: playerInfo.roomCode)

    ws.onClose.whenComplete { _ in
      Task { await roomsService.setWS(nil, for: playerInfo.id, in: playerInfo.roomCode) }
    }
  }
}
