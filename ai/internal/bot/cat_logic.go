package bot

import (
	"math"

	"game-ai/internal/networking"
)

// RunCatLogic executes one cat tick.
// It decides and sends a message directly instead of returning actions.
func RunCatLogic() {
	state := snapshotState()

	if state.Role != "CAT" || state.PlayerPos == nil {
		return
	}

	self := *state.PlayerPos

	var target point
	hasTarget := false
	bestDist := math.MaxFloat64

	for _, p := range state.LastSeenMice {
		d := distance(self, p)
		if d < bestDist {
			bestDist = d
			target = p
			hasTarget = true
		}
	}

	if !hasTarget {
		for _, mem := range state.MemoryByMice {
			d := distance(self, mem.Pos)
			if d < bestDist {
				bestDist = d
				target = mem.Pos
				hasTarget = true
			}
		}
	}

	if !hasTarget || bestDist < moveStep {
		return
	}

	dir := directionToward(self, target)
	networking.SendMove(dir)
}
