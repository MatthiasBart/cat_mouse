import Logic
import Vapor

actor GamesService {
  struct PlayerRegistration {
    let playerId: Int64
    let role: Role
  }

  struct RoomPlayer {
    let playerId: Int64
    let playerName: String
    let role: Role
    let isCreator: Bool
    let isComputer: Bool
  }

  struct GameMetaData {
    let code: String
    let started: Bool
    let players: [RoomPlayer]
  }

  private struct GameEntry {
    let game: Game
    let creatorPlayerId: Int64
    var started: Bool
    var players: [Int64: RoomPlayer]
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

    let creator = RoomPlayer(
      playerId: playerId,
      playerName: playerName,
      role: role,
      isCreator: true,
      isComputer: false
    )

    gameEntries[code] = GameEntry(
      game: game,
      creatorPlayerId: playerId,
      started: false,
      players: [playerId: creator]
    )

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

    let roomPlayer = RoomPlayer(
      playerId: playerId,
      playerName: playerName,
      role: role,
      isCreator: false,
      isComputer: false
    )
    entry.players[playerId] = roomPlayer

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

  func getGameMetaData(code: String) throws -> GameMetaData {
    guard let entry = gameEntries[code] else {
      throw GameError.gameNotFound
    }

    let players = entry.players.values.sorted { lhs, rhs in
      lhs.playerId < rhs.playerId
    }

    return GameMetaData(code: code, started: entry.started, players: players)
  }

  func getRoomPlayer(code: String, playerId: Int64) throws -> RoomPlayer {
    guard let entry = gameEntries[code] else {
      throw GameError.gameNotFound
    }

    guard let player = entry.players[playerId] else {
      throw GameError.invalidData
    }

    return player
  }

  func ensureCreatorCanManageAI(code: String, requesterPlayerId: Int64) throws {
    guard let entry = gameEntries[code] else {
      throw GameError.gameNotFound
    }

    if entry.creatorPlayerId != requesterPlayerId {
      throw GameError.forbidden
    }

    if entry.started {
      throw GameError.gameAlreadyStarted
    }
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
