import Foundation

enum GameError: Int, Error, LocalizedError {
  case unknown = -1
  // 1xxx: Connection/Protocol Errors
  case malformedData = 1001
  case malformedJSON = 1002
  case unknownType = 1003

  // 2xxx: Game Logic Errors
  case invalidMove = 2001
  case outOfBounds = 2002
  case unauthorizedAction = 2003

  var errorDescription: String? {
    switch self {
    case .malformedJSON: return "JSON structure is invalid."
    case .invalidMove: return "That move is physically impossible."
    default: return "Unexpected server error occurred"
    }
  }
}
