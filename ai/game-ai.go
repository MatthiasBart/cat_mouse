package main

import (
	"game-ai/internal/args"
	"game-ai/internal/networking"
)

func main() {
	// PRE-GAME: parsing
	args.ParseAndValidate()
	// PRE-GAME: joining game
	networking.InitApiClient()
	networking.JoinGame(args.Host, args.Code, args.Name, args.Role)
	// PRE-GAME: connecting WS
	networking.ConnectWS(args.Host, args.Code)
	// IN-GAME: TODO:
}
