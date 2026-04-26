package bot

import (
	"encoding/json"
	"game-ai/internal/args"
	"game-ai/internal/networking"
	"log"
)

func ProcessGameError(data *[]byte) {
	var msg networking.ErrorMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		panic("unimplemented")
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
		panic("unimplemented")
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

func ProcessGameInit(data *[]byte) {
	// not sended anymore?
	panic("unimplemented")
}

func ProcessPlayerJoined(data *[]byte) {
	// currently not needed
}

func ProcessGameUpdate(data *[]byte) {
	var msg networking.GameUpdateMessage
	if err := json.Unmarshal(*data, &msg); err == nil {
		switch msg.Player.Role {
		case "mouse":
			panic("unimplemented")
		case "cat":
			processGameUpdateForCat(&msg)
		default:
			log.Printf("unknown player role %q in GAME_UPDATE", msg.Player.Role)
		}
	} else {
		log.Printf("decode GAME_UPDATE: %v", err)
	}
}

func ProcessConnectionInit(data *[]byte) {
	// currently not needed
}

// private helper functions

func isCat() bool {
	return args.Role == "CAT"
}

func isMouse() bool {
	return args.Role == "MOUSE"
}
