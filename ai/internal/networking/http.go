// Package networking handles REST and WebSocket communication with the game server.
package networking

import (
	"log"
	"net/http"
	"net/url"

	"net/http/cookiejar"
	"time"
)

var client *http.Client

// InitApiClient initializes the shared HTTP client and cookie jar.
func InitApiClient() {
	jar, err := cookiejar.New(nil)
	if err != nil {
		log.Fatalf("Failed to create cookie jar: %v", err)
	}

	client = &http.Client{Jar: jar, Timeout: 10 * time.Second}
}

// JoinGame joins a game via REST and persists session cookies in the shared client.
func JoinGame(baseUrl *url.URL, code, name, role string) {
	if client == nil {
		log.Fatal("http client is not initialized")
	}

	request := *baseUrl
	request.Path = "/games/" + url.PathEscape(code) + "/players"
	q := request.Query()
	q.Set("playerName", name)
	q.Set("role", role)
	request.RawQuery = q.Encode()

	res, err := client.Post(request.String(), "application/json", nil)

	if err != nil {
		log.Fatalf("http request failed: %v", err)
	}

	defer res.Body.Close()

	if !(res.StatusCode >= 200 && res.StatusCode < 300) {
		log.Fatalf("Join game failed: %s", res.Status)
	}

	log.Printf("Successfully joined game as %s with role %s", name, role)
}
