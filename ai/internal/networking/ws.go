package networking

import (
	"encoding/json"
	"log"
	"net/http"
	"net/url"

	"github.com/gorilla/websocket"
)

type WSEnvelope struct {
	Type string `json:"type"`
}

type WSHandlers struct {
	OnConnectionInit func(ConnectionInitMessage)
	OnPlayerJoined   func(PlayerJoinedMessage)
	OnGameInit       func(GameInitMessage)
	OnGameUpdate     func(GameUpdateMessage)
	OnCaught         func(CaughtMessage)
	OnVoteResult     func(VoteResultServerMessage)
	OnGameEnded      func(GameEndedMessage)
	OnError          func(ErrorMessage)
}

var Connection *websocket.Conn

func ConnectWS(baseUrl *url.URL, code string) {
	if client == nil {
		log.Fatal("http client is not initialized")
	}

	// ws://{serverHost}/games/{code}/ws
	wsURL := &url.URL{Scheme: "ws", Host: baseUrl.Host, Path: "/games/" + code + "/ws"}
	httpURL := &url.URL{Scheme: "http", Host: wsURL.Host}
	cookies := client.Jar.Cookies(httpURL)
	headers := http.Header{}
	for _, cookie := range cookies {
		headers.Add("Cookie", cookie.String())
	}

	var err error
	Connection, _, err = websocket.DefaultDialer.Dial(wsURL.String(), headers)
	if err != nil {
		log.Fatalf("ws dial failed: %v", err)
	}

	log.Printf("ws connected")
}

// receive messages

func ReadLoop(handlers WSHandlers) {
	for {
		_, data, err := Connection.ReadMessage()
		if err != nil {
			log.Fatal("ws read failed:", err)
		}

		var peek WSEnvelope
		err = json.Unmarshal(data, &peek)
		if err == nil && peek.Type != "" {
			log.Printf("received websocket message type: %s", peek.Type)
			switch peek.Type {
			case "CONNECTION_INIT":
				if handlers.OnConnectionInit != nil {
					var msg ConnectionInitMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode CONNECTION_INIT: %v", err)
						continue
					}
					handlers.OnConnectionInit(msg)
				}
			case "PLAYER_JOINED":
				if handlers.OnPlayerJoined != nil {
					var msg PlayerJoinedMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode PLAYER_JOINED: %v", err)
						continue
					}
					handlers.OnPlayerJoined(msg)
				}
			case "GAME_INIT":
				if handlers.OnGameInit != nil {
					var msg GameInitMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode GAME_INIT: %v", err)
						continue
					}
					handlers.OnGameInit(msg)
				}
			case "GAME_UPDATE":
				if handlers.OnGameUpdate != nil {
					var msg GameUpdateMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode GAME_UPDATE: %v", err)
						continue
					}
					handlers.OnGameUpdate(msg)
				}
			case "CAUGHT":
				if handlers.OnCaught != nil {
					var msg CaughtMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode CAUGHT: %v", err)
						continue
					}
					handlers.OnCaught(msg)
				}
			case "VOTE_RESULT":
				if handlers.OnVoteResult != nil {
					var msg VoteResultServerMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode VOTE_RESULT: %v", err)
						continue
					}
					handlers.OnVoteResult(msg)
				}
			case "GAME_ENDED":
				if handlers.OnGameEnded != nil {
					var msg GameEndedMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode GAME_ENDED: %v", err)
						continue
					}
					handlers.OnGameEnded(msg)
				}
			case "ERROR":
				if handlers.OnError != nil {
					var msg ErrorMessage
					if err := json.Unmarshal(data, &msg); err != nil {
						log.Printf("decode ERROR: %v", err)
						continue
					}
					handlers.OnError(msg)
				}
			}
		}
	}
}

// send messages

func sendClientMessage(msg any) {
	if err := Connection.WriteJSON(msg); err != nil {
		log.Printf("ws write failed: %v", err)
		return
	}
}

func SendMove(dir string) {
	sendClientMessage(MoveMessage{Type: "MOVE", Direction: dir})
}

func SendEnterSubway(subwayID int64) {
	sendClientMessage(EnterSubwayMessage{Type: "ENTER_SUBWAY", SubwayID: subwayID})
}

func SendLeaveSubway(exitID int64) {
	sendClientMessage(LeaveSubwayMessage{Type: "LEAVE_SUBWAY", ExitID: exitID})
}

func SendStartVote() {
	sendClientMessage(StartVoteMessage{Type: "START_VOTE"})
}

func SendLeaveGame() {
	sendClientMessage(LeaveGameMessage{Type: "LEAVE_GAME"})
}

func SendVoteDecision(subwayID int64) {
	sendClientMessage(VoteDecisionMessage{Type: "VOTE_DECISION", TargetSubwayIDVote: subwayID})
}
