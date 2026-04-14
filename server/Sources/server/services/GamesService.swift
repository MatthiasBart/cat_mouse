import Vapor
import Logic

actor GamesService {
  private var games: [String: Game] = [:]

  func createGame() -> String {
      let uuid = UUID().uuidString
      games[uuid] = Game()
      return uuid
  }

  func getGame(key: String) throws -> Game {
      guard let game = games[key] else { 
          throw GameError.invalidData
      }
      return game
  }
}
