import Vapor

/// configures your application
public func configure(_ app: Application) async throws {
  let manager = ClientManager()  // TODO: DI?

  app.lifecycle.use(GameLifecycleHandler(clientManager: manager))

  // register websocket endpoints
  try webSockets(manager, app)
}
