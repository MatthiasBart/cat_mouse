import Logic
import Vapor 

actor Room {
    let game: Game
    var wsStore: [Int64: WebSocket]
    let code: String
    var gameTask: Task<Void, Never>? = nil

    init(game: Game, wsStore: [Int64: WebSocket] = [:], code: String) {
      self.game = game
      self.wsStore = wsStore
      self.code = code
    }

    func startGame() {
        gameTask = Task {
        while true {
            try? await Task.sleep(for: .milliseconds(100))  
            if Task.isCancelled {
              break
            }

            for (player, ws) in wsStore {

            }
        }
        }
    }

    func stopGame() {
      gameTask?.cancel()
      gameTask = nil
    }

    func add(_ ws: WebSocket, for player: Int64) {
      ws.onMessage({ ws, message in 
        try await self.reactTo(message, of: player)
      })      

      wsStore[player] = ws
    }

    func reactTo(_ message: any ClientMessage, of player: Int64) throws {
        if let move = message as? MoveMessage {
          try game.move(player: player, .init(rawValue: move.direction.rawValue)!)
        } else {

        } 
    }

    func deleteWS(for player: Int64) {
      wsStore[player] = nil
    }

    func clean() {
      for (_, ws) in wsStore {
        _ = ws.close()
      }
    }

   func addPlayer(name: String, role: Role) async -> Int64 {
    let playerId: Int64
    switch role {
    case .cat:
      playerId = await game.addCat(name: name)
    case .mouse:
      playerId = await game.addMouse(name: name)
    }

      try? await broadcast(
        PlayerJoinedMessage(
          code: code,
          player: .init(
            playerId: playerId,
            playerName: name,
            role: role,
            isCreator: false,
            isComputer: false
          )
        )
      )

      return playerId
    }

    func broadcast(_ message: ServerMessage) async throws {
      for (_, ws) in wsStore {
        try await ws.send(
          message
        )
      }
    }
  }