import Foundation

enum ServerError: Int, Error, LocalizedError {
  case unknown = -1
  // 1xxx: Invalid Format Errors
  case invalidData = 1001
  case invalidJSON = 1002
  case invalidType = 1003
  case invalidRole = 1004
  case invalidMessage = 10005

  // 2xxx: Game Logic Errors
  case invalidMove = 2001
  case gameNotFound = 2002
  case gameAlreadyStarted = 2003
  case forbidden = 2004
  case gameNotReady = 2005
  case wsConnectionNotFound = 2006

  var errorDescription: String? {
    switch self {
    case .invalidData: "Invalid data."
    case .invalidJSON: "Invalid json."
    case .invalidType: "Invalid message type."
    case .invalidRole: "Invalid role."
    case .invalidMove: "That move is invalid."
    case .invalidMessage: "The sent message was in an incorrect format."
    case .gameNotFound: "Game not found."
    case .gameAlreadyStarted: "Game already started."
    case .forbidden: "You are not allowed to perform this action."
    case .gameNotReady: "Game cannot be started yet."
    default: "Unexpected server error occurred"
    }
  }
}
