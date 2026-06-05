// Package bot stores runtime AI state and role-specific decision procedures.
package bot

import (
	nw "game-ai/internal/networking"
)

// config
const (
	catAvoidCatRadius = 100 // radius within which a cat considers another cat to be "covering" a mouse
)

func processGameUpdateForCat(update *nw.GameUpdateMessage) {
	if len(update.Mice) > 0 {
		targetMouse(update)
	}
	
	if State.target == nil {
		targetRandomSubway(update)
	}

	moveTowardTarget(update)
}

// searches for closest mouse that is not covered by other cats
// and updates the target
func targetMouse(update *nw.GameUpdateMessage) {
	var target *nw.PositionMessage = nil

	for _, mouse := range update.Mice {
		if isMouseCovered(update, mouse) {
			continue
		}
		d := distance(*update.Player.Position, *mouse.Position)
		if target == nil || d < distance(*update.Player.Position, *target) {
			target = mouse.Position
		}
	}

	State.target = target
}

// checks whether any of the cats are within the catAvoidCatRadius
// to the given mouse
func isMouseCovered(update *nw.GameUpdateMessage, mouse nw.MouseStateMessage) bool {
	for _, cat := range update.Cats {
		if cat.ID == update.Player.ID {
			continue
		}
		if distance(*cat.Position, *mouse.Position) <= catAvoidCatRadius {
			return true
		}
	}
	return false
}
