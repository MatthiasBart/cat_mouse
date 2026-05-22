// Package bot stores runtime AI state and role-specific decision procedures.
package bot

import (
	nw "game-ai/internal/networking"
	"math/rand"
	"time"
)

// config
const (
	catAvoidCatRadius = 100
	catSpeed          = 15.0
	deadzone          = (catSpeed / 2) + 5 // and some buffer
)

type catState struct {
	target *nw.PositionMessage
}

var rng = rand.New(rand.NewSource(time.Now().UnixNano()))

var State = catState{
	target: &nw.PositionMessage{X: 0, Y: 0},
}

func processGameUpdateForCat(update *nw.GameUpdateMessage) {
	if len(update.Mice) > 0 {
		// if mouses on surface: follow the closest mouse without another cat nearby.
		chooseMouseTarget(update)
	} else if State.target == nil {
		// else if no target choosen already, pick random
		chooseRandomTarget(update)
	}

	moveTowardTarget(update)
}

func moveTowardTarget(update *nw.GameUpdateMessage) {
	moveToward(*update.Player.Position, *State.target)
	if distance(*update.Player.Position, *State.target) < deadzone {
		// clear target when reached
		State.target = nil
	}
}

func chooseMouseTarget(update *nw.GameUpdateMessage) {
	var target nw.PositionMessage

	for _, mouse := range update.Mice {
		if isMouseCovered(update.Cats, mouse) {
			continue
		}
		d := distance(*update.Player.Position, *mouse.Position)
		if d < distance(*update.Player.Position, target) || target.X == 0 && target.Y == 0 {
			target = *mouse.Position
		}
	}

	State.target = &target
}

func chooseRandomTarget(update *nw.GameUpdateMessage) {
	count := len(update.Subways)
	if count == 0 {
		return
	}
	idx := rng.Intn(count)
	if idx < 0 {
		return
	}

	State.target = &nw.PositionMessage{
		X: update.Subways[idx].Exits[0].X,
		Y: update.Subways[idx].Exits[0].Y,
	}
}

func isMouseCovered(cats []nw.CatStateMessage, mouse nw.MouseStateMessage) bool {
	for _, cat := range cats {
		if distance(*cat.Position, *mouse.Position) <= catAvoidCatRadius {
			return true
		}
	}
	return false
}
