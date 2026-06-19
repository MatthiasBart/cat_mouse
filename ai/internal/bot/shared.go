package bot

import (
	nw "game-ai/internal/networking"
	"math"
	"math/rand"
	"time"
)

type point struct {
	X int64
	Y int64
}

const (
	speed    = 15
	deadzone = (speed / 2) + 5 // used as a buffer for checking if target reached
)

var rng = rand.New(rand.NewSource(time.Now().UnixNano()))

type state struct {
	target    *nw.PositionMessage
}

var State = state{
	target:    nil,
}

// sets target to random exit of random subway
func targetRandomSubway(update *nw.GameUpdateMessage) {
	idx := rng.Intn(len(update.Subways))
	if idx < 0 {
		return
	}

	targetRandomExit(update.Subways[idx])
}

// sets target to random exit of given subway
func targetRandomExit(subway nw.GameUpdateSubway) {
	idx := rng.Intn(len(subway.Exits))
	if idx < 0 {
		return
	}

	State.target = &nw.PositionMessage{
		X: subway.Exits[idx].X,
		Y: subway.Exits[idx].Y,
	}
}

// sets target to closest exit of given subway
func targetClosestExit(subway nw.GameUpdateSubway, currentPos *nw.PositionMessage) {
	var closest *nw.GameUpdateExit
	var closestDist float64 = -1

	for _, exit := range subway.Exits {
		d := distance(*currentPos, nw.PositionMessage{X: exit.X, Y: exit.Y})
		if closest == nil || (d < closestDist) {
			closestDist = d
			closest = &exit
		}
	}

	if closest != nil {
		State.target = &nw.PositionMessage{
			X: closest.X,
			Y: closest.Y,
		}
	}
}

// moves toward currently set target
func moveTowardTarget(update *nw.GameUpdateMessage) {
	moveToward(*update.Player.Position, *State.target)
	if distance(*update.Player.Position, *State.target) < deadzone {
		// clear target when reached
		State.target = nil
		if MouseState.targetSubway != nil {
			nw.SendEnterSubway(MouseState.targetSubway.ID)
			MouseState.targetSubway = nil
		}
	}
}

// sends move message in direction calculated with from/to
func moveToward(from nw.PositionMessage, to nw.PositionMessage) {
	dx := to.X - from.X
	dy := to.Y - from.Y

	var dir string
	if (dx * dx) >= (dy * dy) {
		if dx >= 0 {
			dir = "RIGHT"
		} else {
			dir = "LEFT"
		}
	} else if dy >= 0 {
		dir = "DOWN"
	} else {
		dir = "UP"
	}

	nw.SendMove(dir)
}

// euclidean distance from a to b
func distance(a nw.PositionMessage, b nw.PositionMessage) float64 {
	dx := a.X - b.X
	dy := a.Y - b.Y

	return math.Sqrt(float64(dx*dx + dy*dy))
}
