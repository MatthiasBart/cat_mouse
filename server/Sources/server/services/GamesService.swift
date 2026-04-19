import Logic
import Vapor

actor GamesService {
  struct PlayerRegistration {
    let playerId: Int64
    let role: Role
  }

  private struct GameEntry {
    let game: Game
    let creatorPlayerId: Int64
    var started: Bool
  }

  private var games: [String: Game] = [:]
  private var gameEntries: [String: GameEntry] = [:]

  func createGame(playerName: String, role: Role) -> (
    code: String, registration: PlayerRegistration
  ) {
    let code = UUID().uuidString
    let game = Game()

    let playerId = registerPlayer(game: game, playerName: playerName, role: role)
    let registration = PlayerRegistration(playerId: playerId, role: role)

    let entry = GameEntry(game: game, creatorPlayerId: playerId, started: false)
    gameEntries[code] = entry
    games[code] = game

    return (code, registration)
  }

  func joinGame(code: String, playerName: String, role: Role) throws -> PlayerRegistration {
    guard var entry = gameEntries[code] else {
      throw GameError.gameNotFound
    }

    if entry.started {
      throw GameError.gameAlreadyStarted
    }

    let playerId = registerPlayer(game: entry.game, playerName: playerName, role: role)
    let registration = PlayerRegistration(playerId: playerId, role: role)

    entry = GameEntry(
      game: entry.game, creatorPlayerId: entry.creatorPlayerId, started: entry.started)
    gameEntries[code] = entry

    return registration
  }

  func startGame(code: String, requesterPlayerId: Int64) throws {
    guard var entry = gameEntries[code] else {
      throw GameError.gameNotFound
    }

    if entry.creatorPlayerId != requesterPlayerId {
      throw GameError.forbidden
    }

    if entry.started {
      throw GameError.gameAlreadyStarted
    }

    if !entry.game.gameReady {
      throw GameError.gameNotReady
    }

    entry.game.startGame()
    entry.started = true
    gameEntries[code] = entry
    games[code] = entry.game
  }

  func getGame(key: String) throws -> Game {
    guard let entry = gameEntries[key] else {
      throw GameError.gameNotFound
    }
    return entry.game
  }

  private func registerPlayer(game: Game, playerName: String, role: Role) -> Int64 {
    switch role {
    case .cat:
      return game.addCat(name: playerName)
    case .mouse:
      return game.addMouse(name: playerName)
    }
  }
}
