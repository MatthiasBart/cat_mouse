package bot

import (
	"game-ai/internal/networking"
	"math"
	"time"
)

const (
	mouseThreatRadius   = 100.0
	mouseThreatRadiusSq = mouseThreatRadius * mouseThreatRadius

	holeUnsafeRadius   = 80.0
	holeUnsafeRadiusSq = holeUnsafeRadius * holeUnsafeRadius

	holeTouchRadius   = 22.0
	holeTouchRadiusSq = holeTouchRadius * holeTouchRadius

	mouseMinVector = 0.01

	mouseSubwayLeaveDelay = 3 * time.Second
)

type mouseState struct {
	position         point
	positionKnown    bool
	current_cats     map[int64]point
	target_subway_id int64
	target_exit      point
	target_known     bool

	in_subway         bool
	current_subway    int64
	entered_subway_at time.Time
	leave_sent        bool
}

var MouseState = newMouseState()

func newMouseState() *mouseState {
	return &mouseState{current_cats: make(map[int64]point)}
}

func processGameUpdateForMouse(gameUpdateMessage *networking.GameUpdateMessage) {
	updateMouseState(gameUpdateMessage)
	if MouseState.in_subway {
		processMouseInSubway(gameUpdateMessage)
		return
	}

	if !MouseState.positionKnown {
		return
	}

	// Priority 1: if cats are near, flee and try to enter a safe nearby hole.
	if hasNearbyCats() {
		if tryEnterTouchedSafeHole(gameUpdateMessage) {
			return
		}
		fleeFromNearbyCats()
		return
	}

	// TODO: Vote behavior.

	// Priority 3: move to nearest suitable subway hole.
	if chooseNearestSuitableHole(gameUpdateMessage) {
		if tryEnterTargetHole() {
			return
		}
		moveToward(MouseState.position, MouseState.target_exit)
		return
	}

	// Priority 4: move to first suitable hole.
	if chooseFirstSuitableHole(gameUpdateMessage) {
		if tryEnterTargetHole() {
			return
		}
		moveToward(MouseState.position, MouseState.target_exit)
		return
	}

	// Fallback: if everything is unsafe, run away from visible cats (if any), else do nothing.
	fleeFromVisibleCats()
}

func processMouseInSubway(gameUpdate *networking.GameUpdateMessage) {
	if MouseState.current_subway == 0 {
		return
	}

	if MouseState.leave_sent {
		return
	}

	if time.Since(MouseState.entered_subway_at) < mouseSubwayLeaveDelay {
		return
	}

	exitID, ok := chooseRandomExitForCurrentSubway(gameUpdate)
	if !ok {
		return
	}

	networking.SendLeaveSubway(exitID)
	MouseState.leave_sent = true
}

func updateMouseState(gameUpdate *networking.GameUpdateMessage) {
	if gameUpdate.Player.Subway != nil {
		subwayID := *gameUpdate.Player.Subway
		if !MouseState.in_subway || MouseState.current_subway != subwayID {
			MouseState.entered_subway_at = time.Now()
			MouseState.leave_sent = false
		}
		MouseState.in_subway = true
		MouseState.current_subway = subwayID
		MouseState.positionKnown = false
	} else {
		MouseState.in_subway = false
		MouseState.current_subway = 0
		MouseState.leave_sent = false

		if gameUpdate.Player.Position != nil {
			MouseState.position = point{
				X: float64(gameUpdate.Player.Position.X),
				Y: float64(gameUpdate.Player.Position.Y),
			}
			MouseState.positionKnown = true
		} else {
			MouseState.positionKnown = false
		}
	}

	MouseState.current_cats = make(map[int64]point)
	for _, cat := range gameUpdate.Cats {
		if cat.Position == nil {
			continue
		}
		MouseState.current_cats[cat.ID] = point{
			X: float64(cat.Position.X),
			Y: float64(cat.Position.Y),
		}
	}
}

func chooseRandomExitForCurrentSubway(gameUpdate *networking.GameUpdateMessage) (int64, bool) {
	for _, subway := range gameUpdate.Subways {
		if subway.ID != MouseState.current_subway {
			continue
		}

		if len(subway.Exits) == 0 {
			return 0, false
		}

		randomIndex := int(time.Now().UnixNano() % int64(len(subway.Exits)))
		return subway.Exits[randomIndex].ID, true
	}

	return 0, false
}

func hasNearbyCats() bool {
	for _, cat := range MouseState.current_cats {
		if squaredDistance(MouseState.position, cat) <= mouseThreatRadiusSq {
			return true
		}
	}
	return false
}

func fleeFromNearbyCats() {
	fleeX := 0.0
	fleeY := 0.0
	nearby := 0

	for _, cat := range MouseState.current_cats {
		dx := MouseState.position.X - cat.X
		dy := MouseState.position.Y - cat.Y
		distSq := dx*dx + dy*dy
		if distSq > mouseThreatRadiusSq {
			continue
		}

		nearby++
		if distSq == 0 {
			continue
		}

		dist := math.Sqrt(distSq)
		fleeX += dx / dist
		fleeY += dy / dist
	}

	if nearby == 0 {
		return
	}

	if math.Abs(fleeX) < mouseMinVector && math.Abs(fleeY) < mouseMinVector {
		return
	}

	target := point{X: MouseState.position.X + fleeX, Y: MouseState.position.Y + fleeY}
	moveToward(MouseState.position, target)
}

func fleeFromVisibleCats() {
	if len(MouseState.current_cats) == 0 {
		return
	}

	fleeX := 0.0
	fleeY := 0.0
	for _, cat := range MouseState.current_cats {
		dx := MouseState.position.X - cat.X
		dy := MouseState.position.Y - cat.Y
		distSq := dx*dx + dy*dy
		if distSq == 0 {
			continue
		}
		dist := math.Sqrt(distSq)
		fleeX += dx / dist
		fleeY += dy / dist
	}

	if math.Abs(fleeX) < mouseMinVector && math.Abs(fleeY) < mouseMinVector {
		return
	}

	target := point{X: MouseState.position.X + fleeX, Y: MouseState.position.Y + fleeY}
	moveToward(MouseState.position, target)
}

func chooseNearestSuitableHole(gameUpdate *networking.GameUpdateMessage) bool {
	bestDist := 1e18
	found := false

	for _, subway := range gameUpdate.Subways {
		for _, exit := range subway.Exits {
			exitPoint := point{X: float64(exit.X), Y: float64(exit.Y)}
			if !isHoleSuitable(exitPoint) {
				continue
			}

			d := squaredDistance(MouseState.position, exitPoint)
			if d < bestDist {
				bestDist = d
				MouseState.target_subway_id = subway.ID
				MouseState.target_exit = exitPoint
				MouseState.target_known = true
				found = true
			}
		}
	}

	return found
}

func chooseFirstSuitableHole(gameUpdate *networking.GameUpdateMessage) bool {
	for _, subway := range gameUpdate.Subways {
		for _, exit := range subway.Exits {
			exitPoint := point{X: float64(exit.X), Y: float64(exit.Y)}
			if !isHoleSuitable(exitPoint) {
				continue
			}

			MouseState.target_subway_id = subway.ID
			MouseState.target_exit = exitPoint
			MouseState.target_known = true
			return true
		}
	}

	return false
}

func isHoleSuitable(exit point) bool {
	for _, cat := range MouseState.current_cats {
		if squaredDistance(cat, exit) <= holeUnsafeRadiusSq {
			return false
		}
	}
	return true
}

func tryEnterTouchedSafeHole(gameUpdate *networking.GameUpdateMessage) bool {
	for _, subway := range gameUpdate.Subways {
		for _, exit := range subway.Exits {
			exitPoint := point{X: float64(exit.X), Y: float64(exit.Y)}
			if squaredDistance(MouseState.position, exitPoint) > holeTouchRadiusSq {
				continue
			}
			if !isHoleSuitable(exitPoint) {
				continue
			}
			networking.SendEnterSubway(subway.ID)
			MouseState.target_subway_id = subway.ID
			MouseState.target_exit = exitPoint
			MouseState.target_known = true
			return true
		}
	}
	return false
}

func tryEnterTargetHole() bool {
	if !MouseState.target_known || MouseState.target_subway_id == 0 {
		return false
	}

	if squaredDistance(MouseState.position, MouseState.target_exit) > holeTouchRadiusSq {
		return false
	}

	if !isHoleSuitable(MouseState.target_exit) {
		return false
	}

	networking.SendEnterSubway(MouseState.target_subway_id)
	return true
}
