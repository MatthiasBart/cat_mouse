import Vapor

/// configures your application
public func configure(_ app: Application) async throws {
  let clientsService = ClientsService()  // TODO: DI?

  app.lifecycle.use(GameLifecycleHandler(clientsService: clientsService))
  try routes(app, clientsService: clientsService)
}
