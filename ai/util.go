package main

import (
	"log"
	"net/url"
	"strings"
)

func normalizeRole(role string, out *string) {
	s := strings.ToUpper(strings.TrimSpace(role))
	if s != "CAT" && s != "MOUSE" {
		log.Fatalf("invalid role %q: use cat or mouse", role)
	}
	*out = s
}

func parseHTTPBase(raw string, out **url.URL) {
	u, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		log.Fatalf("invalid --host: %v", err)
	}
	if u.Host == "" {
		log.Fatalf("--host is missing host")
	}
	*out = u
}

func buildWSURL(baseHTTP *url.URL, code string, out **url.URL) {
	wsScheme := "ws"

	u := &url.URL{
		Scheme: wsScheme,
		Host:   baseHTTP.Host,
		Path:   "/games/" + url.PathEscape(code) + "/ws",
	}
	*out = u
}

func cloneURL(u *url.URL, out **url.URL) {
	v := *u
	*out = &v
}
