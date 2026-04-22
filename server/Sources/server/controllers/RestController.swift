//
// RestController.swift
// Holds the REST routes used to manage games,
// e.g creating, joining and starting a game
//

import Vapor
import Foundation

protocol RestControllerProtocol {
  /// Create a new game, returns game code
  func createGame(req: Request) async throws -> Response

  /// Join a game, creates a session and the token
  func joinGame(req: Request) async throws -> Response

  /// Update game state (start, end early, ...)
  func updateGame(req: Request) async throws -> Response
}

struct RestController: RouteCollection {
  private let manager: GamesService
  private let clientsService: ClientsService

  init(gamesService: GamesService, clientsService: ClientsService) {
    self.manager = gamesService
    self.clientsService = clientsService
  }

  private struct PlayerRequest: Content {
    let role: String?
    let playerName: String?
  }

  func boot(routes: any RoutesBuilder) throws {
    let gameRoute = routes.grouped("games")
    gameRoute.post(use: self.createGame)
    gameRoute.post(":code", "players", use: self.joinGame)
    gameRoute.post(":code", "ai", use: self.addAI)
    gameRoute.patch(":code", use: self.updateGame)
  }
}

// MARK: Implementation
extension RestController: RestControllerProtocol {
  func createGame(req: Request) async throws -> Response {
    let playerRequest = try req.query.decode(PlayerRequest.self)
    let role = try parseRole(from: playerRequest.role)
    let playerName = parsePlayerName(from: playerRequest.playerName)

    let (key, registration) = await manager.createGame(playerName: playerName, role: role)

    let session = PlayerSession(
      req: req,
      playerId: registration.playerId,
      role: registration.role,
      playerName: playerName,
      code: key
    )
    session.save()

    req.logger.info("Player \(session.playerName) created game \(session.code)")
    return try await session.output.encodeResponse(status: .created, for: req)
  }

  func joinGame(req: Request) async throws -> Response {
    guard let code = req.parameters.get(PlayerSession.codeKey), !code.isEmpty else {
      throw Abort(.badRequest, reason: "Game code is missing")
    }

    let playerRequest = try req.query.decode(PlayerRequest.self)
    let role = try parseRole(from: playerRequest.role)
    let playerName = parsePlayerName(from: playerRequest.playerName)

    let registration: GamesService.PlayerRegistration
    do {
      registration = try await manager.joinGame(code: code, playerName: playerName, role: role)
    } catch let error as GameError {
      throw mapToAbort(error)
    }

    let session = PlayerSession(
      req: req,
      playerId: registration.playerId,
      role: registration.role,
      playerName: playerName,
      code: code
    )
    session.save()

    req.logger.info("Player \(session.playerName) joined game \(session.code)")

    do {
      let joinedPlayer = try await manager.getRoomPlayer(code: code, playerId: registration.playerId)
      let payload = PlayerJoined(
        code: code,
        player: ConnectionInit.PlayerInfo(
          playerId: joinedPlayer.playerId,
          playerName: joinedPlayer.playerName,
          role: joinedPlayer.role,
          isCreator: joinedPlayer.isCreator,
          isComputer: joinedPlayer.isComputer
        )
      )
      await clientsService.broadcast(message: payload, in: code)
    } catch {
      req.logger.warning("Failed to broadcast PLAYER_JOINED for code \(code): \(error)")
    }

    return try await session.output.encodeResponse(status: .ok, for: req)
  }

  func updateGame(req: Request) async throws -> Response {
    guard let code = req.parameters.get(PlayerSession.codeKey), !code.isEmpty else {
      throw Abort(.badRequest, reason: "Game code is missing")
    }

    guard let session = PlayerSession(req: req) else {
      throw Abort(.unauthorized, reason: "Missing or invalid session")
    }

    guard session.code == code else {
      throw Abort(.forbidden, reason: "Session does not belong to this game")
    }

    do {
      try await manager.startGame(code: code, requesterPlayerId: session.playerId)
    } catch let error as GameError {
      throw mapToAbort(error)
    }

    return Response(status: .noContent)
  }

  func addAI(req: Request) async throws -> Response {
    guard let code = req.parameters.get(PlayerSession.codeKey), !code.isEmpty else {
      throw Abort(.badRequest, reason: "Game code is missing")
    }

    guard let session = PlayerSession(req: req) else {
      throw Abort(.unauthorized, reason: "Missing or invalid session")
    }

    guard session.code == code else {
      throw Abort(.forbidden, reason: "Session does not belong to this game")
    }

    let playerRequest = try req.query.decode(PlayerRequest.self)
    let role = try parseRole(from: playerRequest.role)

    do {
      try await manager.ensureCreatorCanManageAI(code: code, requesterPlayerId: session.playerId)
    } catch let error as GameError {
      throw mapToAbort(error)
    }

    do {
      try spawnAIProcess(req: req, code: code, role: role)
    } catch {
      req.logger.error("Failed to spawn AI process for game \(code): \(error)")
      throw Abort(.internalServerError, reason: "Failed to start AI process")
    }

    return Response(status: .noContent)
  }

  private func parsePlayerName(from rawName: String?) -> String {
    let trimmed = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if trimmed.isEmpty {
      return "Anonymous"
    }
    return trimmed
  }

  private func parseRole(from role: String?) throws -> Role {
    guard let parsedRole = Role.parse(apiValue: role) else {
      throw Abort(.badRequest, reason: "Missing or invalid role. Use 'cat' or 'mouse'.")
    }
    return parsedRole
  }

  private func mapToAbort(_ error: GameError) -> Abort {
    switch error {
    case .gameNotFound:
      return Abort(.notFound, reason: error.localizedDescription)
    case .gameAlreadyStarted:
      return Abort(.conflict, reason: error.localizedDescription)
    case .forbidden:
      return Abort(.forbidden, reason: error.localizedDescription)
    case .gameNotReady:
      return Abort(.conflict, reason: error.localizedDescription)
    case .invalidRole:
      return Abort(.badRequest, reason: error.localizedDescription)
    default:
      return Abort(.badRequest, reason: error.localizedDescription)
    }
  }

  private func spawnAIProcess(req: Request, code: String, role: Role) throws {
    // NOTE: make sure the binary is built
    let aiBinaryPath = "../ai/game-ai" 
    let roleArgument: String

    switch role {
    case .cat:
      roleArgument = "cat"
    case .mouse:
      roleArgument = "mouse"
    }

    let aiName = "ai-\(roleArgument)-\(UUID().uuidString.prefix(8))"

    let process = Process()
    process.executableURL = URL(fileURLWithPath: aiBinaryPath)
    process.arguments = [
      "--host=http://localhost:8080",
      "--code=\(code)",
      "--role=\(roleArgument)",
      "--name=\(aiName)",
    ]

    req.logger.notice(
      "Spawning AI process path=\(aiBinaryPath) code=\(code) role=\(roleArgument) name=\(aiName)")

    try process.run()

    req.logger.notice(
      "Spawned AI process pid=\(process.processIdentifier) for game \(code) as \(role.rawValue)")
  }
}
