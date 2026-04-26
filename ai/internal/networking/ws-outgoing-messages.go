package networking

// ==== OUTGOING MESSAGES (client -> server) ====

type MoveMessage struct {
	Type      string `json:"type"`
	Direction string `json:"direction"`
}

type EnterSubwayMessage struct {
	Type     string `json:"type"`
	SubwayID int64  `json:"subwayId"`
}

type LeaveSubwayMessage struct {
	Type   string `json:"type"`
	ExitID int64  `json:"exitId"`
}

type StartVoteMessage struct {
	Type string `json:"type"`
}

type LeaveGameMessage struct {
	Type string `json:"type"`
}

type VoteDecisionMessage struct {
	Type               string `json:"type"`
	TargetSubwayIDVote int64  `json:"target_subway_id_vote"`
}
