package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gorilla/websocket"
)

func main() {
	// parse options
	var host = flag.String("host", "http://localhost:8080", "server host")
	var code = flag.String("code", "", "game code for join mode")
	var name = flag.String("name", "ai-bot", "bot player name")
	var role = flag.String("role", "mouse", "cat or mouse")

	flag.Parse()

	if strings.TrimSpace(*code) == "" {
		log.Fatal("--code is required in join mode")
	}

	var normalizedRole string
	normalizeRole(*role, &normalizedRole)

	// http client and join game
	jar, err := cookiejar.New(nil)
	if err != nil {
		log.Fatalf("create cookie jar: %v", err)
	}

	httpClient := &http.Client{Jar: jar, Timeout: 10 * time.Second}

	var baseHTTP *url.URL
	parseHTTPBase(*host, &baseHTTP)

	var session sessionResponse
	joinGame(
		httpClient,
		baseHTTP,
		strings.TrimSpace(*code),
		*name,
		normalizedRole,
		&session,
	)

	log.Printf("joined game with code=%s role=%s name=%s", session.Code, session.Role, session.PlayerName)

	// websocket connection
	var wsURL *url.URL
	buildWSURL(baseHTTP, session.Code, &wsURL)
	var conn *websocket.Conn
	connectWS(jar, wsURL, &conn)
	defer conn.Close()

	log.Printf("ws connected: %s", wsURL.String())

	// prepare context for clean up on shutdown
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	errCh := make(chan error, 4)
	// read loop in goroutine next to main loop
	go readLoop(conn, errCh)

	// main loop
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Printf("shutdown signal received")
			_ = conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, "bye"))
			return
		case err := <-errCh:
			if err != nil {
				log.Printf("loop ended: %v", err)
			}
			return
		case <-ticker.C:
			dir := "UP" // TODO: implement movement strategy based on roles and received messages
			sendMove(conn, dir, errCh)
			log.Printf("sent MOVE %s", dir)
		}
	}
}
