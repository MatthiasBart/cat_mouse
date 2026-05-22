package bot

import (
	nw "game-ai/internal/networking"
	"math"
)

type point struct {
	X int64
	Y int64
}

// moveToward sends a single step toward the target point.
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

// computes squared distance between two points
func squaredDistance(a nw.PositionMessage, b nw.PositionMessage) float64 {
	dx := a.X - b.X
	dy := a.Y - b.Y

	return float64(dx*dx + dy*dy)
}

func distance(a nw.PositionMessage, b nw.PositionMessage) float64 {
	dx := a.X - b.X
	dy := a.Y - b.Y

	return math.Sqrt(float64(dx*dx + dy*dy))
}
