package networking

// ConnectionInitPlayer represents one player entry in a CONNECTION_INIT message.
type ConnectionInitPlayer struct {
	PlayerID   int64  `json:"playerId"`
	PlayerName string `json:"playerName"`
	Role       string `json:"role"`
	IsCreator  bool   `json:"isCreator"`
	IsComputer bool   `json:"isComputer"`
}

// ConnectionInitMessage represents a CONNECTION_INIT server message.
type ConnectionInitMessage struct {
	Type            string                 `json:"type"`
	Code            string                 `json:"code"`
	Started         bool                   `json:"started"`
	CurrentPlayerID int64                  `json:"currentPlayerId"`
	Players         []ConnectionInitPlayer `json:"players"`
}

// PlayerJoinedMessage represents a PLAYER_JOINED server message.
type PlayerJoinedMessage struct {
	Type   string `json:"type"`
	Code   string `json:"code"`
	Player struct {
		PlayerID   int64  `json:"playerId"`
		PlayerName string `json:"playerName"`
		Role       string `json:"role"`
		IsCreator  bool   `json:"isCreator"`
		IsComputer bool   `json:"isComputer"`
	} `json:"player"`
}

// GameInitFieldSize represents the field size in a GAME_INIT message.
type GameInitFieldSize struct {
	Width  int64 `json:"width"`
	Height int64 `json:"height"`
}

// GameInitExit represents one subway exit in a GAME_INIT message.
type GameInitExit struct {
	ID int64 `json:"id"`
	X  int64 `json:"x"`
	Y  int64 `json:"y"`
}

// GameInitSubway represents one subway in a GAME_INIT message.
type GameInitSubway struct {
	ID    int64          `json:"id"`
	Name  string         `json:"name,omitempty"`
	Exits []GameInitExit `json:"exits"`
}

// PositionMessage represents a 2D position in WS payloads.
type PositionMessage struct {
	X int64 `json:"x"`
	Y int64 `json:"y"`
}

// GameInitMessage represents a GAME_INIT server message.
type GameInitMessage struct {
	Type           string             `json:"type"`
	Code           string             `json:"code,omitempty"`
	Role           string             `json:"role"`
	PlayerPosition *PositionMessage   `json:"playerPosition,omitempty"`
	FieldSize      *GameInitFieldSize `json:"fieldSize,omitempty"`
	Subways        []GameInitSubway   `json:"subways,omitempty"`
}

// PlayerStateMessage represents the current player state in a GAME_UPDATE message.
type PlayerStateMessage struct {
	ID       int64            `json:"id"`
	Name     string           `json:"name"`
	Role     string           `json:"role"`
	Subway   *int64           `json:"subway,omitempty"`
	Position *PositionMessage `json:"position,omitempty"`
	Caught   int64            `json:"caught"`
}

// MouseStateMessage represents one mouse entry in a GAME_UPDATE message.
type MouseStateMessage struct {
	ID       int64            `json:"id"`
	Name     string           `json:"name"`
	Subway   *int64           `json:"subway,omitempty"`
	Position *PositionMessage `json:"position,omitempty"`
}

// CatStateMessage represents one cat entry in a GAME_UPDATE message.
type CatStateMessage struct {
	ID       int64            `json:"id"`
	Name     string           `json:"name"`
	TypeName string           `json:"type"`
	Subway   *int64           `json:"subway,omitempty"`
	Position *PositionMessage `json:"position,omitempty"`
}

// VoteEntryMessage represents one subway vote count in an active vote.
type VoteEntryMessage struct {
	SubwayID int64 `json:"subwayId"`
	Votes    int64 `json:"votes"`
}

// ActiveVoteMessage represents the active vote section of a GAME_UPDATE message.
type ActiveVoteMessage struct {
	TimeLeft int64              `json:"timeLeft"`
	Votes    []VoteEntryMessage `json:"votes"`
}

// GameUpdateExit represents one exit entry in a GAME_UPDATE message.
type GameUpdateExit struct {
	ID int64 `json:"id"`
	X  int64 `json:"x"`
	Y  int64 `json:"y"`
}

// GameUpdateSubway represents one subway entry in a GAME_UPDATE message.
type GameUpdateSubway struct {
	ID    int64            `json:"id"`
	Exits []GameUpdateExit `json:"exits"`
}

// ErrorMessage represents an ERROR server message.
type ErrorMessage struct {
	Type    string `json:"type"`
	Code    int64  `json:"code"`
	Message string `json:"message"`
}

// GameUpdateMessage represents a GAME_UPDATE server message.
type GameUpdateMessage struct {
	Type       string              `json:"type"`
	Seq        int64               `json:"seq"`
	TimeLeft   int64               `json:"timeLeft"`
	Player     PlayerStateMessage  `json:"player"`
	Mice       []MouseStateMessage `json:"mice"`
	Cats       []CatStateMessage   `json:"cats"`
	ActiveVote *ActiveVoteMessage  `json:"active_vote,omitempty"`
	Subways    []GameUpdateSubway  `json:"subways,omitempty"`
}

// CaughtMessage represents a CAUGHT server message.
type CaughtMessage struct {
	Type string `json:"type"`
}

// VoteResultMessage represents a VOTE_RESULT server message.
type VoteResultMessage struct {
	Type      string `json:"type"`
	WinSubway int64  `json:"win_subway"`
}

// GameEndedWinner represents the winner payload in a GAME_ENDED message.
type GameEndedWinner struct {
	ID            int64  `json:"id"`
	Name          string `json:"name"`
	TypeName      string `json:"type"`
	Caught        *int64 `json:"caught,omitempty"`
	TimeOnSurface *int64 `json:"timeOnSurface,omitempty"`
}

// GameEndedMessage represents a GAME_ENDED server message.
type GameEndedMessage struct {
	Type      string          `json:"type"`
	Player    GameEndedWinner `json:"player"`
	TotalTime int64           `json:"totalTime"`
}
