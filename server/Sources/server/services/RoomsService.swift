import Logic
import Vapor

private let logger = Logger(label: "RoomsService")

actor RoomsService {
  var rooms: [String: Room] = [:]

  func getWS(of player: Int64, in room: String) async -> WebSocket? {
      await rooms[room]?.wsStore[player]
  }

  func setWS(_ ws: WebSocket?, for player: Int64, in room: String) async {
    if let ws {
      if let room = rooms[room] {
        await room.add(ws, for: player)
        logger.info("sending connection init to \(player) in \(room)")

        let players = await room.playerInfos()


        try? await ws.send(
          ConnectionInitMessage(
            code: room.code,
            currentPlayerId: player,
            players: players
          )
        )
      }
    } else {
      await rooms[room]?.deleteWS(for: player)
    }
  }

  func clean() async {
      logger.critical("All rooms get cleaned")
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

    logger.info("room \(room) from \(playerName) with id \(playerId) created")

    return (code, playerId)
  }

  func joinRoom(code: String, playerName: String, role: Role) async throws -> Int64 {
    guard let room = rooms[code] else {
      throw ServerError.gameNotFound
    }

    let playerId = await room.addPlayer(name: playerName, role: role)

    logger.info("\(playerName) joined \(room) and got \(playerId)")

    return playerId
  }
}
