import Foundation

enum GameError: Int, Error, LocalizedError {
  case unknown = -1
  // 1xxx: Invalid Format Errors
  case invalidData = 1001
  case invalidJSON = 1002
  case invalidType = 1003

  // 2xxx: Game Logic Errors
  case invalidMove = 2001

  var errorDescription: String? {
    switch self {
    case .invalidData: "Invalid data."
    case .invalidJSON: "Invalid json."
    case .invalidType: "Invalid message type."
    case .invalidMove: "That move is invalid."
    default: "Unexpected server error occurred"
    }
  }
}
