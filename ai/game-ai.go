package main

import (
	"game-ai/internal/args"
	"game-ai/internal/bot"
	"game-ai/internal/networking"
	"log"
	"os"
	"os/signal"
	"time"
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
	// IN-GAME: start read & write loop
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)
	status := make(chan GameStatus, PREGAME)

	go readLoop(status)
	s := <-status
	if s == INGAME {
		log.Printf("Game started, starting bot logic...")
		writeLoop(status, interrupt)
	}
	if s == ENDED {
		log.Printf("Game ended before it started, exiting...")
	}
}

func readLoop(status chan GameStatus) {
	defer close(status)

	started := false
	for {
		msg_type, data, err := networking.ReadMessageWithType()
		if err != nil {
			status <- ENDED
			return
		}

		if msg_type != "GAME_UPDATE" {
			log.Printf("received websocket message type: %s", msg_type)
		}
		switch msg_type {
		case "GAME_UPDATE":
			if !started {
				// start game on first GAME_UPDATE message
				started = true
				status <- INGAME
			}
			bot.ProcessGameUpdate(&data)
		case "GAME_ENDED":
			bot.ProcessGameEnded(&data)
			status <- ENDED
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

func writeLoop(status chan GameStatus, interrupt chan os.Signal) {
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case s := <-status:
			if s == ENDED {
				log.Printf("Game ended, exiting write loop...")
				networking.SendLeaveGame()
			} else {
				// this shoould not happen in current game flow, but log just in case
				log.Printf("Game status changed: %v", s)
			}
			return
		case <-interrupt:
			log.Printf("Interrupted, sending leave game message and exiting...")
			networking.SendLeaveGame()
			return
		case <-ticker.C:
			networking.SendMove("UP") // example
		}
	}
}
