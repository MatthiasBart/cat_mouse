import Vapor 

extension WebSocket {
  func send(_ message: any ServerMessage) async throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(message)
    guard let collection = String(data: data, encoding: .utf8) else {
        throw ServerError.invalidMessage
    }
    try await self.send(collection)
  }

  func onMessage(_ callback: @escaping @Sendable (WebSocket, any ClientMessage) async throws -> ()) {
    let decoder = JSONDecoder()
    onText({ ws, text in
      guard
        let data = text.data(using: .utf8),
        let anyMessage = try? decoder.decode(AnyClientMessage.self, from: data)
      else {
        try? await ws.send(ErrorMessage(.invalidMessage))
        return 
      }

    do {
      switch anyMessage.type {
        case .move:
          let moveMessage = try decoder.decode(MoveMessage.self, from: data)
          try await callback(ws, moveMessage)
        case .enterSubway:
          let enterSubwayMessage = try decoder.decode(EnterSubwayMessage.self, from: data)
          try await callback(ws, enterSubwayMessage)
        case .leaveSubway:
          let leaveSubwayMessage = try decoder.decode(LeaveSubwayMessage.self, from: data)
          try await callback(ws, leaveSubwayMessage)
        case .startVote:
          let startVotingMessage = try decoder.decode(StartVotingMessage.self, from: data)
          try await callback(ws, startVotingMessage)
        case .leaveGame:
          let leaveGameMessage = try decoder.decode(LeaveGameMessage.self, from: data)
          try await callback(ws, leaveGameMessage)
        case .voteDecision:
          let voteDecisionMessage = try decoder.decode(VoteDecisionMessage.self, from: data)
          try await callback(ws, voteDecisionMessage)
      }
    } catch {
        try? await ws.send(ErrorMessage(.invalidMessage))
    }
    })
  }
}