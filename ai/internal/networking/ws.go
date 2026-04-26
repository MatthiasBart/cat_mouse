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

// WSHandlers contains callbacks for incoming WebSocket message types.
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

// Connection is the shared active WebSocket connection.
var Connection *websocket.Conn

// ConnectWS opens the WebSocket connection for a game code.
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

// ReadLoop reads incoming WebSocket messages and dispatches them to handlers.
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

// sendClientMessage sends one client message over the shared connection.
func sendClientMessage(msg any) {
	if err := Connection.WriteJSON(msg); err != nil {
		log.Printf("ws write failed: %v", err)
		return
	}
}

// SendMove sends a MOVE command.
func SendMove(dir string) {
	sendClientMessage(MoveMessage{Type: "MOVE", Direction: dir})
}

// SendEnterSubway sends an ENTER_SUBWAY command.
func SendEnterSubway(subwayID int64) {
	sendClientMessage(EnterSubwayMessage{Type: "ENTER_SUBWAY", SubwayID: subwayID})
}

// SendLeaveSubway sends a LEAVE_SUBWAY command.
func SendLeaveSubway(exitID int64) {
	sendClientMessage(LeaveSubwayMessage{Type: "LEAVE_SUBWAY", ExitID: exitID})
}

// SendStartVote sends a START_VOTE command.
func SendStartVote() {
	sendClientMessage(StartVoteMessage{Type: "START_VOTE"})
}

// SendLeaveGame sends a LEAVE_GAME command.
func SendLeaveGame() {
	sendClientMessage(LeaveGameMessage{Type: "LEAVE_GAME"})
}

// SendVoteDecision sends a VOTE_DECISION command.
func SendVoteDecision(subwayID int64) {
	sendClientMessage(VoteDecisionMessage{Type: "VOTE_DECISION", TargetSubwayIDVote: subwayID})
}
