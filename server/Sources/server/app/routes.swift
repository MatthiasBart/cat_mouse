import Vapor

func routes(_ app: Application, clientsService: ClientsService) throws {
  try app.register(collection: GameController())
  try app.register(collection: GameSocketController(clientsService: clientsService))
}
