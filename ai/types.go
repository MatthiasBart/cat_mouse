package main

type sessionResponse struct {
	Code       string `json:"code"`
	Role       string `json:"role"`
	PlayerName string `json:"playerName"`
	PlayerID   int64  `json:"playerId"`
}

type wsEnvelope struct {
	Type string `json:"type"`
}
