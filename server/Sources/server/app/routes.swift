import Vapor

func routes(_ app: Application, clientsService: ClientsService, gamesService: GamesService) throws {
  try app.register(collection: GameController(gamesService: gamesService, clientsService: clientsService))
  try app.register(collection: GameSocketController(clientsService: clientsService, gamesService: gamesService))
}
