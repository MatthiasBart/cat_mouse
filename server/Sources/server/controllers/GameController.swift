//
// GameController.swift
// Holds the REST routes used to manage games,
// e.g creating, joining and starting a game
//

import Vapor

protocol GameControllerProtocol {
  /// Create a new game, returns game code
  func createGame(req: Request) async throws -> Response

  /// Join a game, creates a session and the token
  func joinGame(req: Request) async throws -> Response

  /// Update game state (start, end early, ...)
  func updateGame(req: Request) async throws -> Response
}

struct GameController: RouteCollection {
  private let manager: GamesService = GamesService()

  func boot(routes: any RoutesBuilder) throws {
    let gameRoute = routes.grouped("games")
    gameRoute.post(use: self.createGame)
    gameRoute.post(":code", "players", use: self.joinGame)
    gameRoute.patch(":code", use: self.updateGame)
  }
}

// MARK: Implementation
extension GameController: GameControllerProtocol {
  // TODO: prevent player from joining/creating multiple games with same session
  func createGame(req: Request) async throws -> Response {
    let key = await manager.createGame()

    let session = PlayerSession(req: req, code: key)
    session.save()

    req.logger.info("Player \(session.playerName) created game \(session.code)")
    return try await session.output.encodeResponse(status: .created, for: req)
  }

  func joinGame(req: Request) async throws -> Response {
    guard let code = req.parameters.get(PlayerSession.codeKey), !code.isEmpty else {
      throw Abort(.badRequest, reason: "Game code is missing")
    }

    let session = PlayerSession(req: req, code: code)
    session.save()

    req.logger.info("Player \(session.playerName) joined game \(session.code)")
    return try await session.output.encodeResponse(status: .ok, for: req)
  }

  func updateGame(req: Request) async throws -> Response {
    throw Abort(.notImplemented)  // Use Abort to throw HTTP errors cleanly
  }

  private func joinUrl(from code: String) -> String {
    "ws://localhost:8080/\(code)/ws"  // TODO: use real server url
  }
}
