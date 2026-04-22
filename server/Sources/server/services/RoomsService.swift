import Logic
import Vapor

actor RoomsService {
  var rooms: [String: Room] = [:]

  func getWS(of player: Int64, in room: String) async -> WebSocket? {
      await rooms[room]?.wsStore[player]
  }

  func setWS(_ ws: WebSocket?, for player: Int64, in room: String) async {
    if let ws {
      if let room = rooms[room] {
        await room.add(ws, for: player)

        try? await ws.send(
          ConnectionInitMessage(
            code: room.code,
            currentPlayerId: player,
            players: []
          )
        )
      }
    } else {
      await rooms[room]?.deleteWS(for: player)
    }
  }

  func clean() async {
    for room in rooms {
        await room.value.clean()
    }
  }

  func createRoom(playerName: String, role: Role) async -> (code: String, playerId: Int64) {
    let code = UUID().uuidString
    let game = Game()
    let room = Room(game: game, code: code)

    rooms[code] = room

    let playerId = await room.addPlayer(name: playerName, role: role)

    return (code, playerId)
  }

  func joinRoom(code: String, playerName: String, role: Role) async throws -> Int64 {
    guard let room = rooms[code] else {
      throw ServerError.gameNotFound
    }

    let playerId = await room.addPlayer(name: playerName, role: role)

    return playerId
  }
}
