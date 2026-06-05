package bot

import (
	"encoding/json"
	"game-ai/internal/networking"
	"log"
	"strings"
)

func ProcessGameError(data *[]byte) {
	var msg networking.ErrorMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		log.Fatalf("Received error %v", err)
	} else {
		log.Printf("decode ERROR: %v", err)
	}
}

func ProcessGameEnded(data *[]byte) {
	var msg networking.GameEndedMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		panic("unimplemented")
	} else {
		log.Printf("decode GAME_ENDED: %v", err)
	}
}

func ProcessVoteResult(data *[]byte) {
	var msg networking.VoteResultMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		processVoteResultForMouse(msg.WinSubway)
	} else {
		log.Printf("decode VOTE_RESULT: %v", err)
	}
}

func ProcessCaught(data *[]byte) {
	var msg networking.CaughtMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		panic("unimplemented")
	} else {
		log.Printf("decode CAUGHT: %v", err)
	}
}

func ProcessGameUpdate(data *[]byte) {
	var msg networking.GameUpdateMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		switch strings.ToLower(msg.Player.Role) {
		case "mouse":
			processGameUpdateForMouse(&msg)
		case "cat":
			processGameUpdateForCat(&msg)
		default:
			log.Printf("unknown player role %q in GAME_UPDATE", msg.Player.Role)
		}
	} else {
		log.Printf("decode GAME_UPDATE: %v", err)
	}
}
