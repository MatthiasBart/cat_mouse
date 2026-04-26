package networking

// ==== INCOMING MESSAGES (server -> client) ====
type ConnectionInitPlayer struct {
	PlayerID   int64  `json:"playerId"`
	PlayerName string `json:"playerName"`
	Role       string `json:"role"`
	IsCreator  bool   `json:"isCreator"`
	IsComputer bool   `json:"isComputer"`
}

type ConnectionInitMessage struct {
	Type            string                 `json:"type"`
	Code            string                 `json:"code"`
	Started         bool                   `json:"started"`
	CurrentPlayerID int64                  `json:"currentPlayerId"`
	Players         []ConnectionInitPlayer `json:"players"`
}

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

type GameInitFieldSize struct {
	Width  int64 `json:"width"`
	Height int64 `json:"height"`
}

type GameInitExit struct {
	ID int64 `json:"id"`
	X  int64 `json:"x"`
	Y  int64 `json:"y"`
}

type GameInitSubway struct {
	ID    int64          `json:"id"`
	Name  string         `json:"name,omitempty"`
	Exits []GameInitExit `json:"exits"`
}

type PositionMessage struct {
	X int64 `json:"x"`
	Y int64 `json:"y"`
}

type GameInitMessage struct {
	Type           string             `json:"type"`
	Code           string             `json:"code,omitempty"`
	Role           string             `json:"role"`
	PlayerPosition *PositionMessage   `json:"playerPosition,omitempty"`
	FieldSize      *GameInitFieldSize `json:"fieldSize,omitempty"`
	Subways        []GameInitSubway   `json:"subways,omitempty"`
}

type PlayerStateMessage struct {
	ID       int64            `json:"id"`
	Name     string           `json:"name"`
	Role     string           `json:"role"`
	Subway   *int64           `json:"subway,omitempty"`
	Position *PositionMessage `json:"position,omitempty"`
	Caught   int64            `json:"caught"`
}

type MouseStateMessage struct {
	ID       int64            `json:"id"`
	Name     string           `json:"name"`
	Subway   *int64           `json:"subway,omitempty"`
	Position *PositionMessage `json:"position,omitempty"`
}

type CatStateMessage struct {
	ID       int64            `json:"id"`
	Name     string           `json:"name"`
	TypeName string           `json:"type"`
	Subway   *int64           `json:"subway,omitempty"`
	Position *PositionMessage `json:"position,omitempty"`
}

type VoteEntryMessage struct {
	SubwayID int64 `json:"subwayId"`
	Votes    int64 `json:"votes"`
}

type ActiveVoteMessage struct {
	TimeLeft int64              `json:"timeLeft"`
	Votes    []VoteEntryMessage `json:"votes"`
}

type GameUpdateExit struct {
	ID int64 `json:"id"`
	X  int64 `json:"x"`
	Y  int64 `json:"y"`
}

type GameUpdateSubway struct {
	ID    int64            `json:"id"`
	Exits []GameUpdateExit `json:"exits"`
}

type ErrorMessage struct {
	Type    string `json:"type"`
	Code    int64  `json:"code"`
	Message string `json:"message"`
}

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

type CaughtMessage struct {
	Type string `json:"type"`
}

type VoteResultServerMessage struct {
	Type      string `json:"type"`
	WinSubway int64  `json:"win_subway"`
}

type GameEndedWinner struct {
	ID            int64  `json:"id"`
	Name          string `json:"name"`
	TypeName      string `json:"type"`
	Caught        *int64 `json:"caught,omitempty"`
	TimeOnSurface *int64 `json:"timeOnSurface,omitempty"`
}

type GameEndedMessage struct {
	Type      string          `json:"type"`
	Player    GameEndedWinner `json:"player"`
	TotalTime int64           `json:"totalTime"`
}
