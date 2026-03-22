import Vapor

/// configures your application
public func configure(_ app: Application) async throws {
  let manager = ClientManager()  // TODO: DI?

  app.lifecycle.use(GameLifecycleHandler(clientManager: manager))

  try app.register(collection: GameController(clientManager: manager))
}
