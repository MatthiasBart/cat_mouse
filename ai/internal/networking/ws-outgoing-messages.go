package networking

// MoveMessage represents a MOVE client message.
type MoveMessage struct {
	Type      string `json:"type"`
	Direction string `json:"direction"`
}

// EnterSubwayMessage represents an ENTER_SUBWAY client message.
type EnterSubwayMessage struct {
	Type     string `json:"type"`
	SubwayID int64  `json:"subwayId"`
}

// LeaveSubwayMessage represents a LEAVE_SUBWAY client message.
type LeaveSubwayMessage struct {
	Type   string `json:"type"`
	ExitID int64  `json:"exitId"`
}

// StartVoteMessage represents a START_VOTE client message.
type StartVoteMessage struct {
	Type string `json:"type"`
}

// LeaveGameMessage represents a LEAVE_GAME client message.
type LeaveGameMessage struct {
	Type string `json:"type"`
}

// VoteDecisionMessage represents a VOTE_DECISION client message.
type VoteDecisionMessage struct {
	Type               string `json:"type"`
	TargetSubwayIDVote int64  `json:"target_subway_id_vote"`
}
