import Foundation

class Controller {
    var games: [String: Game] = [:]

    init() {}

    func createGame(with name: String) throws {
        if games[name] != nil {
            throw GameError.gameAlreadyExists
        }

        games[name] = Game()
    }
}

enum GameError: Error {
    case gameAlreadyExists
}

class Game {
    let players: [Player]

    let subways: [Subway]

    private(set) var stop: Bool = false

    init() {
        players = []
        subways = []

        gameLoop()
    }

    func gameLoop() {
        while true {
            if stop {
                sendStopState()
                break
            }

            for player in players {
                sendGameState(for: player.id)
            }
        }
    }

    func sendStopState() {}

    func stopGame() {
        stop = true
    }

    func sendGameState(for clientID: Int64) {
        _ = computeGameState(for: clientID)
    }

    func computeGameState(for _: Int64) -> Data {
        return Data()
    }
}

struct Player {
    let id: Int64
    let role: Role = .undefined
}

enum Role {
    case undefined
    case mouse(Mouse)
    case cat(Cat)
}
