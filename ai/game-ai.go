package main

import (
	"game-ai/internal/args"
	"game-ai/internal/bot"
	"game-ai/internal/networking"
	"log"
)

type GameStatus int

const (
	PREGAME GameStatus = iota
	INGAME
	ENDED
)

func main() {
	// PRE-GAME: parsing args, joining game, connecting WS
	args.ParseAndValidate()
	networking.InitApiClient()
	networking.JoinGame(args.Host, args.Code, args.Name, args.Role)
	networking.ConnectWS(args.Host, args.Code)
	// IN-GAME: read loop
	readLoop()
	networking.SendLeaveGame()
}

func readLoop() {
	for {
		msg_type, data, err := networking.ReadMessageWithType()
		if err != nil {
			log.Printf("Error reading message: %v", err)
			return
		}

		if msg_type != "GAME_UPDATE" {
			log.Printf("received websocket message type: %s", msg_type)
		}
		switch msg_type {
		case "GAME_UPDATE":
			bot.ProcessGameUpdate(&data)
		case "GAME_ENDED":
			bot.ProcessGameEnded(&data)
			log.Printf("Game ended")
			return
		case "CONNECTION_INIT":
			bot.ProcessConnectionInit(&data)
		case "PLAYER_JOINED":
			bot.ProcessPlayerJoined(&data)
		case "GAME_INIT":
			bot.ProcessGameInit(&data)
		case "CAUGHT":
			bot.ProcessCaught(&data)
		case "VOTE_RESULT":
			bot.ProcessVoteResult(&data)
		case "ERROR":
			bot.ProcessGameError(&data)
		}
	}
}
