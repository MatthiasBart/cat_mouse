import Vapor

actor GamesService {
  private var codes: Set<String> = []

  func createGame() -> (Bool, String) {
    codes.insert(UUID().uuidString)
  }
}
