package main

import (
	"game-ai/internal/args"
	"game-ai/internal/bot"
	"game-ai/internal/networking"
	"log"
	"os"
	"os/signal"
	"syscall"
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

	// signal handler
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		log.Println("Received termination signal, leaving game...")
		if networking.Connection != nil {
			networking.SendLeaveGame()
		}
		os.Exit(0)
	}()

	// IN-GAME: read loop
	readLoop()
	if networking.Connection != nil {
		networking.SendLeaveGame()
	}
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
		case "CONNECTION_INIT", "PLAYER_JOINED":
			log.Printf("Ignoring message of type %s", msg_type)
		case "GAME_UPDATE":
			bot.ProcessGameUpdate(&data)
		case "VOTE_RESULT":
			bot.ProcessVoteResult(&data)
		case "ERROR":
			bot.ProcessGameError(&data)
		case "GAME_ENDED":
			log.Printf("Game ended")
			return
		case "CAUGHT":
			log.Printf("Caught")
			return
		}
	}
}
