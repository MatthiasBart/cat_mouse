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
	// prioritize mouse on surface, only move toward remembered position if no mouse on surface
	var target point
	hasTarget := false
	minDist := 1e9

	if len(State.current_mice) > 0 {
		for _, mouse := range State.current_mice {
			d := squaredDistance(State.position, mouse)
			if d < minDist {
				minDist = d
				target = mouse
				hasTarget = true
			}
		}
	} else {
		for _, mouse := range State.remembered_mice {
			d := squaredDistance(State.position, mouse)
			if d < minDist {
				minDist = d
				target = mouse
				hasTarget = true
			}
		}
	}
	if !hasTarget {
		return
	}
	moveToward(State.position, target)
}

func updateState(gameUpdate *networking.GameUpdateMessage) {
	if gameUpdate.Player.Position != nil {
		// cat should always have a position, but check just in case
		State.position = point{
			X: float64(gameUpdate.Player.Position.X),
			Y: float64(gameUpdate.Player.Position.Y),
		}
	}

	prevMice := State.current_mice
	State.current_mice = make(map[int64]point)

	for _, mouse := range gameUpdate.Mice {
		if mouse.Position != nil {
			p := point{
				X: float64(mouse.Position.X),
				Y: float64(mouse.Position.Y),
			}
			State.current_mice[mouse.ID] = p
			delete(State.remembered_mice, mouse.ID)
		}
		// else the mouse entered hole,
		// therefore last position is remembered
	}

	for id, p := range prevMice {
		if _, stillVisible := State.current_mice[id]; !stillVisible {
			State.remembered_mice[id] = p
		}
	}
}
