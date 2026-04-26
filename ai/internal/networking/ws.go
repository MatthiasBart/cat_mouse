package networking

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"

	"github.com/gorilla/websocket"
)

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

// ReadMessageWithType reads one message from the shared connection and returns its type and raw data.
func ReadMessageWithType() (string, []byte, error) {
	_, data, err := Connection.ReadMessage()
	if err != nil {
		return "", nil, err
	}

	var peek struct {
		Type string `json:"type"`
	}
	err = json.Unmarshal(data, &peek)
	if peek.Type != "" {
		return peek.Type, data, nil
	} else {
		return "", nil, fmt.Errorf("message missing type field")
	}
}

// sendMessage sends one client message over the shared connection.
func sendMessage(msg any) {
	if err := Connection.WriteJSON(msg); err != nil {
		log.Printf("WSERROR: %v", err)
		return
	}
}

// SendMove sends a MOVE command.
func SendMove(dir string) {
	sendMessage(MoveMessage{Type: "MOVE", Direction: dir})
}

// SendEnterSubway sends an ENTER_SUBWAY command.
func SendEnterSubway(subwayID int64) {
	sendMessage(EnterSubwayMessage{Type: "ENTER_SUBWAY", SubwayID: subwayID})
}

// SendLeaveSubway sends a LEAVE_SUBWAY command.
func SendLeaveSubway(exitID int64) {
	sendMessage(LeaveSubwayMessage{Type: "LEAVE_SUBWAY", ExitID: exitID})
}

// SendStartVote sends a START_VOTE command.
func SendStartVote() {
	sendMessage(StartVoteMessage{Type: "START_VOTE"})
}

// SendLeaveGame sends a LEAVE_GAME command.
func SendLeaveGame() {
	sendMessage(LeaveGameMessage{Type: "LEAVE_GAME"})
}

// SendVoteDecision sends a VOTE_DECISION command.
func SendVoteDecision(subwayID int64) {
	sendMessage(VoteDecisionMessage{Type: "VOTE_DECISION", TargetSubwayIDVote: subwayID})
}
