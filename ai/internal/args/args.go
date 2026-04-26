// Package args parses and validates command-line arguments.
package args

import (
	"flag"
	"log"
	"net/url"
	"strings"
)

var Host *url.URL
var Code string
var Name string
var Role string

// ParseAndValidate parses CLI flags, validates values, and stores them in package globals.
func ParseAndValidate() {
	name := flag.String("name", "ai-bot", "bot player name")
	code := flag.String("code", "", "game code for join mode")
	role := flag.String("role", "mouse", "cat or mouse")
	host := flag.String("host", "http://localhost:8080", "server host")

	flag.Parse()

	// name not empty
	Name = strings.TrimSpace(*name)
	if Name == "" {
		log.Fatal("--name cannot be empty")
	}
	// code not empty
	Code = strings.TrimSpace(*code)
	if strings.TrimSpace(Code) == "" {
		log.Fatal("--code is required in join mode")
	}
	// role is cat or mouse
	Role = strings.ToLower(strings.TrimSpace(*role))
	if Role != "cat" && Role != "mouse" {
		log.Fatalf("invalid role %q: use cat or mouse", Role)
	}
	// host is valid URL
	var err error
	Host, err = url.Parse(strings.TrimSpace(*host))
	if err != nil {
		log.Fatalf("invalid --host: %v", err)
	}
	if Host.Host == "" {
		log.Fatal("--host must include scheme and host, e.g. http://localhost:8080")
	}
}
