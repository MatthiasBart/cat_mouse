// Package bot stores runtime AI state and role-specific decision procedures.
package bot

import (
	"game-ai/internal/networking"
)

const (
	moveStep = 20.0
)

type catState struct {
	position        point
	current_mice    map[int64]point
	remembered_mice map[int64]point
}

var State = newState()

func newState() *catState {
	return &catState{
		current_mice:    make(map[int64]point),
		remembered_mice: make(map[int64]point),
	}
}

func processGameUpdateForCat(gameUpdateMessage *networking.GameUpdateMessage) {
	updateState(gameUpdateMessage)
	// find either closest mouse or closest remembered mouse, and move toward it
	var target point
	minDist := 1e9
	for _, mouse := range State.current_mice {
		d := squaredDistance(State.position, mouse)
		if d < minDist {
			minDist = d
			target = mouse
		}
	}
	for _, mouse := range State.remembered_mice {
		d := squaredDistance(State.position, mouse)
		if d < minDist {
			minDist = d
			target = mouse
		}
	}
	moveToward(State.position, target)
}

func updateState(gameUpdate *networking.GameUpdateMessage) {
	for _, mouse := range gameUpdate.Mice {
		if mouse.Position != nil {
			State.current_mice[mouse.ID] = point{
				X: float64(mouse.Position.X),
				Y: float64(mouse.Position.Y),
			}
		}
		// else the mouse entered hole,
		// therefore last position is remembered
	}
}
