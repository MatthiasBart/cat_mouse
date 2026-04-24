import Logic
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

    func startGame() {
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
                    type: winner is Cat ? "CAT" : "MOUSE",
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
        if let move = message as? MoveMessage {
            try game.move(player: player, .init(rawValue: move.direction.rawValue)!)
        } else if let leave = message as? LeaveSubwayMessage {
            try game.leave(exit: leave.exitId, mouse: player)
        } else if let enter = message as? EnterSubwayMessage {
            try game.enter(subway: enter.subwayId, mouse: player)
        } else if let _ = message as? StartVotingMessage {
            try game.startVoting(manager: player)
        } else if let _ = message as? LeaveGameMessage {
            game.leaveGame(player: player)
            let _ = wsStore[player]?.close()
            deleteWS(for: player)
        } else if let vote = message as? VoteDecisionMessage {
            try game.vote(subway: vote.target_subway_id_vote, mouse: player)
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

        if game.players.count == 1 {
            game.creator = playerId
            logger.info("creator \(name) joined with \(playerId)")
        } else {
            logger.info("player \(name) joined with \(playerId)")
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

    func broadcast(_ message: any ServerMessage) async throws {
        for (_, ws) in wsStore {
            try await ws.send(
                message
            )
        }
    }
}
