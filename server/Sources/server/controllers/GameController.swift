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
  func createGame(req: Request) async throws -> Response {
    let (_, code) = await manager.createGame()

    let session = PlayerSession(req: req, code: code)
    session.save()

    return try await session.output.encodeResponse(status: .created, for: req)
  }

  func joinGame(req: Request) async throws -> Response {
    guard let code = req.parameters.get(PlayerSession.codeKey), !code.isEmpty else {
      throw Abort(.badRequest, reason: "Game code is missing or invalid")
    }

    let playerName: String? = req.query[PlayerSession.playerNameKey]
    let session = PlayerSession(req: req, code: code, playerName: playerName)
    session.save()

    return try await session.output.encodeResponse(status: .ok, for: req)
  }

  func updateGame(req: Request) async throws -> Response {
    throw Abort(.notImplemented)  // Use Abort to throw HTTP errors cleanly
  }

  private func joinUrl(from code: String) -> String {
    "ws://localhost:8080/\(code)/ws"  // TODO: use real server url
  }
}

// Mark: Player Session

struct PlayerSession {
  struct Output: Content {
    let role: Role
    let playerName: String
    let code: String
  }

  static let playerNameKey = "playerName"
  static let codeKey = "code"

  let role: Role
  let playerName: String
  let code: String
  let req: Request

  init(req: Request, code: String, playerName: String? = nil) {
    self.playerName = playerName ?? "Anonymous"
    self.code = code
    self.req = req
    self.role = .random  // TODO: not random role assignment
  }

  func save() {
    self.req.session.data[Self.playerNameKey] = self.playerName
    self.req.session.data[Self.codeKey] = self.code
  }

  var output: Output {
    Output(role: self.role, playerName: self.playerName, code: self.code)
  }
}
