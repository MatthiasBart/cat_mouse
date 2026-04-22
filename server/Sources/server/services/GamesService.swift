import Logic
import Vapor

actor GamesService {
  struct PlayerRegistration {
    let playerId: Int64
    let role: Role
  }

  private var games: [String: Game] = [:]

  func createGame(playerName: String, role: Role) -> (code: String, registration: PlayerRegistration) {
    let code = UUID().uuidString
    let game = Game()

    let playerId = addPlayer(to: game, playerName: playerName, role: role)
    let registration = PlayerRegistration(playerId: playerId, role: role)

    games[code] = game

    return (code, registration)
  }

  func joinGame(code: String, playerName: String, role: Role) throws -> PlayerRegistration {
    guard let game = games[code] else {
      throw GameError.gameNotFound
    }

    let playerId = addPlayer(to: game, playerName: playerName, role: role)
    let registration = PlayerRegistration(playerId: playerId, role: role)

    return registration
  }

  func startGame(code: String, requesterPlayerId: Int64) throws {
    guard let game = games[code] else {
      throw GameError.gameNotFound
    }

    game.startGame()
  }

  func getGame(code: String) throws -> Game {
    guard let game = games[code] else {
      throw GameError.gameNotFound
    }
    return game
  }

  private func addPlayer(to game: Game, playerName: String, role: Role) -> Int64 {
    switch role {
    case .cat:
      return game.addCat(name: playerName)
    case .mouse:
      return game.addMouse(name: playerName)
    }
  }
}
