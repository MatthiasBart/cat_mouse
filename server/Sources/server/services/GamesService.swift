import Vapor

actor GamesService {
  private var codes: Set<String> = []

  func createGame() -> (Bool, String) {
    codes.insert(UUID().uuidString)
  }

  func gameExists(code: String) -> Bool {
    codes.contains(code)
  }
}
