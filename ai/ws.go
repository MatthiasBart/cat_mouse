package main

import (
	"encoding/json"
	"log"
	"net/http"
	"net/url"

	"github.com/gorilla/websocket"
)

func connectWS(jar http.CookieJar, wsURL *url.URL, connOut **websocket.Conn) {
	httpURL := &url.URL{Scheme: "http", Host: wsURL.Host}
	if wsURL.Scheme == "wss" {
		httpURL.Scheme = "https"
	}

	cookies := jar.Cookies(httpURL)
	headers := http.Header{}
	for _, cookie := range cookies {
		headers.Add("Cookie", cookie.String())
	}

	conn, resp, err := websocket.DefaultDialer.Dial(wsURL.String(), headers)
	if err != nil {
		if resp != nil {
			log.Fatalf("ws dial failed: %v (status %s)", err, resp.Status)
		}
		log.Fatalf("ws dial failed: %v", err)
	}

	*connOut = conn
}

func readLoop(conn *websocket.Conn, errCh chan<- error) {
	for {
		_, data, err := conn.ReadMessage()
		if err != nil {
			errCh <- err
			return
		}

		log.Printf("recv: %s", string(data))

		var peek wsEnvelope
		if err := json.Unmarshal(data, &peek); err == nil && peek.Type != "" {
			log.Printf("recv type: %s", peek.Type)
			switch peek.Type {
			case "GAME_UPDATE":
				processGameUpdate(data)
			}
		}
	}
}

// handle incoming messages

func processGameUpdate(data []byte) {
	var msg gameUpdateMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		log.Printf("decode GAME_UPDATE: %v", err)
		return
	}

	log.Printf("game state: %+v", msg)
}

// send outgoing messages

func sendMove(conn *websocket.Conn, dir string, errCh chan<- error) {
	msg := moveMessage{Type: "MOVE", Test: dir}
	if err := conn.WriteJSON(msg); err != nil {
		errCh <- err
		return
	}
}
