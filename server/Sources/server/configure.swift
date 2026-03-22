import Vapor

/// configures your application
public func configure(_ app: Application) async throws {
  // register websocket endpoints
  try webSockets(app)
}
