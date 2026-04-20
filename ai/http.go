package main

import (
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strings"
)

func joinGame(client *http.Client, baseHTTP *url.URL, code, name, role string, out *sessionResponse) {
	var endpoint *url.URL
	cloneURL(baseHTTP, &endpoint)

	endpoint.Path = "/games/" + url.PathEscape(code) + "/players"
	q := endpoint.Query()
	q.Set("playerName", name)
	q.Set("role", role)
	endpoint.RawQuery = q.Encode()

	req, err := http.NewRequest(http.MethodPost, endpoint.String(), nil)
	if err != nil {
		log.Fatalf("join request: %v", err)
	}

	makeSessionRequest(client, req, out)
}

func makeSessionRequest(client *http.Client, req *http.Request, out *sessionResponse) {
	res, err := client.Do(req)
	if err != nil {
		log.Fatalf("http request failed: %v", err)
	}
	defer res.Body.Close()

	if !(res.StatusCode >= 200 && res.StatusCode < 300) {
		log.Fatalf("unexpected status %s", res.Status)
	}

	if err := json.NewDecoder(res.Body).Decode(out); err != nil {
		log.Fatalf("decode session response: %v", err)
	}

	if strings.TrimSpace(out.Code) == "" {
		log.Fatalf("missing code in session response")
	}
}
