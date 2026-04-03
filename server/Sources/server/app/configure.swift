import Vapor

/// configures your application
public func configure(_ app: Application) async throws {
  let clientsService = ClientsService()  // TODO: DI?

    let cors = CORSMiddleware(configuration: .init(
    allowedOrigin: .custom("http://localhost:5173"),
    allowedMethods: [.GET, .POST, .PATCH, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith],
    allowCredentials: true
  ))
  app.middleware.use(cors, at: .beginning)

  app.middleware.use(app.sessions.middleware)
  app.lifecycle.use(GameLifecycleHandler(clientsService: clientsService))
  try routes(app, clientsService: clientsService)
}
