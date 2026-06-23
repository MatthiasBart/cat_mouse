import Vapor

private let logger = Logger(label: "Room")

extension Room: @preconcurrency GameDelegate {
    func gotCaught(_ mouse: Int64) {
        if let ws = wsStore[mouse] {
            Task { try? await ws.send(CaughtMessage()) }
        }
    }

    func voteResult(_ subway: Int64, for mice: [Mouse.ID]) {
        for (player, ws) in wsStore { 
            if mice.contains(player) {
                Task { try? await ws.send(VoteResultMessage(win_subway: subway)) }
            }
        }
    }
}

actor Room {
    let game: Game
    var wsStore: [Int64: WebSocket]
    let code: String
    var gameTask: Task<Void, Never>? = nil

    init(game: Game, wsStore: [Int64: WebSocket] = [:], code: String) {
        self.game = game
        self.wsStore = wsStore
        self.code = code
        self.game.gameDelegate = self
    }

    func startGame() throws {
        if !game.gameReady {
            throw ServerError.gameNotReady
        }

        gameTask = Task {
            game.startGame()
            logger.info("game loop started \(self.code)")
            while game.endTime > Date() {
                try? await Task.sleep(for: .milliseconds(100))
                if Task.isCancelled {
                    break
                }

                game.checkGameState()

                for (player, ws) in wsStore {
                    if let updateMessage = try? await GameStateCalculator(game: game)
                        .computeGameState(for: player)
                    {
                        try? await ws.send(updateMessage)
                    }
                }
            }
            logger.info("game loop stopped \(self.code)")
            game.endGame()

            if let winner = game.winner {
                try? await broadcast(GameEndedMessage(
                    player: .init(
                        id: winner.id,
                        name: winner.name,
                        type: winner.role.rawValue,
                        caught: (winner as? Cat).map { Int64($0.caught.count) },
                        timeOnSurface: (winner as? Mouse).map { Int64($0.totalTimeOnSurface) }
                    ),
                    totalTime: Int64(Game.duration)
                ))
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
        try message.execute(on: game, by: player)
        if message.type == .leaveGame {
            let _ = wsStore[player]?.close()
            deleteWS(for: player)
        }
    }

    func deleteWS(for player: Int64) {
        wsStore[player] = nil
    }

    func clean() {
        logger.critical("cleaning \(code)")
        for (_, ws) in wsStore {
            _ = ws.close()
        }
    }

    func addPlayer(name: String, role: Role) async -> Int64 {
        let playerId: Int64
        switch role {
        case .cat:
            playerId = game.addCat(name: name)
        case .mouse:
            playerId = game.addMouse(name: name)
        }

        logger.info("player \(name) joined with \(playerId)")

        try? await broadcast(
            PlayerJoinedMessage(
                code: code,
                player: .init(
                    playerId: playerId,
                    playerName: name,
                    role: role,
                    isCreator: game.creator == playerId,
                    isComputer: false
                )
            )
        )

        return playerId
    }

    func playerInfos() -> [ConnectionInitMessage.PlayerInfo] {
        game.players.map { player in
            ConnectionInitMessage.PlayerInfo(
                playerId: player.id,
                playerName: player.name,
                role: player.role,
                isCreator: game.creator == player.id,
                isComputer: false
            )
        }
    }

    func broadcast(_ message: any ServerMessage) async throws {
        for (_, ws) in wsStore {
            try await ws.send(
                message
            )
        }
    }
}
