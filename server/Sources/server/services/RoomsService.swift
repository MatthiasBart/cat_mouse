import Logic
import Vapor

actor RoomsService {
  class Room {
    var game: Game
    var wsStore: [Int64: WebSocket]

    init(game: Game, wsStore: [Int64: WebSocket] = [:]) {
      self.game = game
      self.wsStore = wsStore
    }
  }

  private var rooms: [String: Room] = [:]

  func getWS(of player: Int64, in room: String) -> WebSocket? {
      rooms[room]?.wsStore[player]
  }

  func setWS(_ ws: WebSocket?, for player: Int64, in room: String) {
      rooms[room]?.wsStore[player] = ws
  }

  func clean(room roomCode: String) {
    guard let room = rooms[roomCode] else {
      return
    }
    for (_, ws) in room.wsStore {
      _ = ws.close()
    }

    room.game.endGame()
    rooms[roomCode] = nil
  }

  func clean() {
    for room in rooms {
        clean(room: room.key)
    }
  }

  func createRoom(playerName: String, role: Role) -> (code: String, playerId: Int64) {
    let code = UUID().uuidString
    let game = Game()
    let room = Room(game: game)

    rooms[code] = room

    let playerId = addPlayer(to: room, name: playerName, role: role)

    return (code, playerId)
  }

  func joinRoom(code: String, playerName: String, role: Role) async throws -> Int64 {
    guard let room = rooms[code] else {
      throw ServerError.gameNotFound
    }

    let playerId = addPlayer(to: room, name: playerName, role: role)

    for (_, ws) in room.wsStore {
      try await ws.send(
        PlayerJoinedMessage(
          code: code,
          player: .init(
            playerId: playerId,
            playerName: playerName,
            role: role,
            isCreator: false,
            isComputer: false
          )
        )
      )
    }

    return playerId
  }

  func startGame(in room: String, playerId: Int64) throws {
    guard let room = rooms[room] else {
      throw ServerError.gameNotFound
    }

    room.game.startGame()
  }

  private func addPlayer(to room: Room, name: String, role: Role) -> Int64 {
    switch role {
    case .cat:
      return room.game.addCat(name: name)
    case .mouse:
      return room.game.addMouse(name: name)
    }
  }
}
