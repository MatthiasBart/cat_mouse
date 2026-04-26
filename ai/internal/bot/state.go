// Package bot stores runtime AI state and role-specific decision procedures.
package bot

import (
	"math"
	"strings"
	"sync"
	"time"

	"game-ai/internal/networking"
)

const (
	moveStep        = 20.0
	memoryMaxAgeSec = 20
)

type point struct {
	X float64
	Y float64
}

type exitInfo struct {
	ID int64
	X  int64
	Y  int64
}

type holeMemory struct {
	ExitID  int64
	Pos     point
	SeenAt  time.Time
	MouseID int64
}

type aiState struct {
	mu sync.RWMutex

	CurrentPlayerID int64
	Role            string
	PlayerPos       *point

	KnownExits []exitInfo

	LastSeenMice map[int64]point
	MemoryByMice map[int64]holeMemory

	GameCode       string
	GameStarted    bool
	LastVoteResult *int64
}

// State is the shared in-memory AI state.
var State = newAIState()

type stateSnapshot struct {
	CurrentPlayerID int64
	Role            string
	PlayerPos       *point
	KnownExits      []exitInfo
	LastSeenMice    map[int64]point
	MemoryByMice    map[int64]holeMemory
	GameCode        string
	GameStarted     bool
	LastVoteResult  *int64
}

func newAIState() *aiState {
	return &aiState{
		LastSeenMice: make(map[int64]point),
		MemoryByMice: make(map[int64]holeMemory),
	}
}

// SetRole sets the bot role in shared state.
func SetRole(role string) {
	State.mu.Lock()
	defer State.mu.Unlock()
	State.Role = strings.ToUpper(strings.TrimSpace(role))
}

// SaveConnectionInit saves fields from a CONNECTION_INIT message.
func SaveConnectionInit(msg *networking.ConnectionInitMessage) {
	if msg == nil {
		return
	}

	State.mu.Lock()
	defer State.mu.Unlock()

	if msg.CurrentPlayerID != 0 {
		State.CurrentPlayerID = msg.CurrentPlayerID
	}
	State.GameCode = msg.Code
	State.GameStarted = msg.Started
}

// SaveGameInit saves fields from a GAME_INIT message.
func SaveGameInit(msg *networking.GameInitMessage) {
	if msg == nil {
		return
	}

	State.mu.Lock()
	defer State.mu.Unlock()

	if msg.Code != "" {
		State.GameCode = msg.Code
	}
	if msg.Role != "" {
		State.Role = strings.ToUpper(strings.TrimSpace(msg.Role))
	}
	if msg.PlayerPosition != nil {
		State.PlayerPos = &point{X: float64(msg.PlayerPosition.X), Y: float64(msg.PlayerPosition.Y)}
	}
}

// SaveGameUpdate saves fields from a GAME_UPDATE message and updates simple memory.
func SaveGameUpdate(msg *networking.GameUpdateMessage) {
	if msg == nil {
		return
	}

	now := time.Now()

	State.mu.Lock()
	defer State.mu.Unlock()

	if msg.Player.Position != nil {
		State.PlayerPos = &point{X: float64(msg.Player.Position.X), Y: float64(msg.Player.Position.Y)}
	} else {
		State.PlayerPos = nil
	}

	State.KnownExits = flattenExits(msg.Subways)

	currentVisible := make(map[int64]point)
	for _, m := range msg.Mice {
		if m.Position == nil {
			continue
		}
		p := point{X: float64(m.Position.X), Y: float64(m.Position.Y)}
		currentVisible[m.ID] = p
		delete(State.MemoryByMice, m.ID)
	}

	for id, prevPos := range State.LastSeenMice {
		if _, stillVisible := currentVisible[id]; stillVisible {
			continue
		}

		exit, ok := nearestExit(prevPos, State.KnownExits)
		if !ok {
			continue
		}

		State.MemoryByMice[id] = holeMemory{
			ExitID:  exit.ID,
			Pos:     point{X: float64(exit.X), Y: float64(exit.Y)},
			SeenAt:  now,
			MouseID: id,
		}
	}

	for id, mem := range State.MemoryByMice {
		if now.Sub(mem.SeenAt) > memoryMaxAgeSec*time.Second {
			delete(State.MemoryByMice, id)
		}
	}

	State.LastSeenMice = currentVisible
}

// SaveVoteResult saves fields from a VOTE_RESULT message.
func SaveVoteResult(msg *networking.VoteResultServerMessage) {
	if msg == nil {
		return
	}

	State.mu.Lock()
	defer State.mu.Unlock()

	value := msg.WinSubway
	State.LastVoteResult = &value
}

func snapshotState() stateSnapshot {
	State.mu.RLock()
	defer State.mu.RUnlock()

	copyLastSeen := make(map[int64]point, len(State.LastSeenMice))
	for id, p := range State.LastSeenMice {
		copyLastSeen[id] = p
	}

	copyMemory := make(map[int64]holeMemory, len(State.MemoryByMice))
	for id, mem := range State.MemoryByMice {
		copyMemory[id] = mem
	}

	var playerPos *point
	if State.PlayerPos != nil {
		p := *State.PlayerPos
		playerPos = &p
	}

	var voteResult *int64
	if State.LastVoteResult != nil {
		v := *State.LastVoteResult
		voteResult = &v
	}

	return stateSnapshot{
		CurrentPlayerID: State.CurrentPlayerID,
		Role:            State.Role,
		PlayerPos:       playerPos,
		KnownExits:      append([]exitInfo(nil), State.KnownExits...),
		LastSeenMice:    copyLastSeen,
		MemoryByMice:    copyMemory,
		GameCode:        State.GameCode,
		GameStarted:     State.GameStarted,
		LastVoteResult:  voteResult,
	}
}

func directionToward(from point, to point) string {
	dx := to.X - from.X
	dy := to.Y - from.Y

	if math.Abs(dx) >= math.Abs(dy) {
		if dx >= 0 {
			return "RIGHT"
		}
		return "LEFT"
	}

	if dy >= 0 {
		return "DOWN"
	}
	return "UP"
}

func distance(a point, b point) float64 {
	dx := a.X - b.X
	dy := a.Y - b.Y
	return math.Sqrt(dx*dx + dy*dy)
}

func flattenExits(subways []networking.GameUpdateSubway) []exitInfo {
	exits := make([]exitInfo, 0, 16)
	for _, s := range subways {
		for _, e := range s.Exits {
			exits = append(exits, exitInfo{ID: e.ID, X: e.X, Y: e.Y})
		}
	}
	return exits
}

func nearestExit(from point, exits []exitInfo) (exitInfo, bool) {
	if len(exits) == 0 {
		return exitInfo{}, false
	}

	best := exits[0]
	bestDist := distance(from, point{X: float64(best.X), Y: float64(best.Y)})

	for i := 1; i < len(exits); i++ {
		d := distance(from, point{X: float64(exits[i].X), Y: float64(exits[i].Y)})
		if d < bestDist {
			best = exits[i]
			bestDist = d
		}
	}

	return best, true
}
