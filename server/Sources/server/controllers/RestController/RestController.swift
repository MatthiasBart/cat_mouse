//
// RestController.swift
// Holds the REST routes used to manage games,
// e.g creating, joining and starting a game
//

import Vapor
import Foundation

struct RestController: RouteCollection {
  let roomsService: RoomsService

  init(roomsService: RoomsService) {
    self.roomsService = roomsService
  }

  func boot(routes: any RoutesBuilder) throws {
    let gameRoute = routes.grouped("games")
    gameRoute.post(use: self.createGame)
    gameRoute.post(":code", "players", use: self.joinGame)
    gameRoute.post(":code", "ai", use: self.addAI)
    gameRoute.patch(":code", use: self.startGame)
  }

  func parsePlayerName(from rawName: String?) -> String {
    let trimmed = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if trimmed.isEmpty {
      return "Anonymous"
    }
    return trimmed
  }

  func parseRole(from role: String?) throws -> Role {
    guard let parsedRole = Role.parse(apiValue: role) else {
      throw Abort(.badRequest, reason: "Missing or invalid role. Use 'cat' or 'mouse'.")
    }
    return parsedRole
  }

  func mapToAbort(_ error: ServerError) -> Abort {
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
}
