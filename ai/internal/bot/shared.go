package bot

import (
	"game-ai/internal/networking"
	"math"
)

type point struct {
	X float64
	Y float64
}

func moveToward(from point, to point) {
	dx := to.X - from.X
	dy := to.Y - from.Y

	var dir string
	if math.Abs(dx) >= math.Abs(dy) {
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

	networking.SendMove(dir)
}

func squaredDistance(a point, b point) float64 {
	dx := a.X - b.X
	dy := a.Y - b.Y
	// squared distance is enough for comparison
	return dx*dx + dy*dy
}
