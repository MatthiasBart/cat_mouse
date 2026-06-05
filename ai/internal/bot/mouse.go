package bot

import (
	nw "game-ai/internal/networking"
	"log"
)

const (
	mouseAvoidCatRadius = 50 // radius within which a mouse tries to run away from a cat
)

type mouseState struct {
	winSubway    *int64
	currentVote  *nw.VoteEntryMessage
	targetSubway *nw.GameUpdateSubway // needed for entering subway
}

var MouseState = mouseState{}

func processVoteResultForMouse(winSubway int64) {
	MouseState.winSubway = &winSubway
	MouseState.currentVote = nil
}

func processGameUpdateForMouse(update *nw.GameUpdateMessage) {
	if update.Player.Subway != nil {
		processGameUpdateInsideSubway(update)
	} else {
		processGameUpdateOutsideSubway(update)
	}
}

/* ====== Inside Subway ====== */

func processGameUpdateInsideSubway(update *nw.GameUpdateMessage) {
	if MouseState.winSubway != nil {
		if *update.Player.Subway == *MouseState.winSubway {
			// We've arrived at the winning subway, so clear it
			MouseState.winSubway = nil
		} else {
			leaveSubwayViaRandomExit(update)
		}
	}

	if MouseState.winSubway == nil {
		if update.ActiveVote == nil {
			nw.SendStartVote()
		} else {
			vote(update)
		}
	}
}

func vote(update *nw.GameUpdateMessage) {
	// only vote if current vote is not set
	if MouseState.currentVote == nil {
		rand_idx := rng.Intn(len(update.ActiveVote.Votes))
		MouseState.currentVote = &update.ActiveVote.Votes[rand_idx]
		nw.SendVoteDecision(MouseState.currentVote.SubwayID)
	}
}

func leaveSubwayViaRandomExit(update *nw.GameUpdateMessage) {
	// find current subway
	var subway *nw.GameUpdateSubway
	for i := range update.Subways {
		if update.Subways[i].ID == *update.Player.Subway {
			subway = &update.Subways[i]
			break
		}
	}

	if subway != nil && len(subway.Exits) > 0 {
		// leave via random exit
		rand_idx := rng.Intn(len(subway.Exits))
		nw.SendLeaveSubway(subway.Exits[rand_idx].ID)
	} else {
		log.Println("Cannot leave current subway, not found or no exits!")
	}
}

/* ====== Outside Subway ====== */

func processGameUpdateOutsideSubway(update *nw.GameUpdateMessage) {
	runAwayIfCatNearby(update)

	if State.target == nil && MouseState.winSubway != nil {
		targetWinningSubway(update)
	}

	if State.target == nil {
		idx := rng.Intn(len(update.Subways))
		if idx < 0 {
			return
		}

		MouseState.targetSubway = &update.Subways[idx]
		targetRandomExit(*MouseState.targetSubway)
	}

	moveTowardTarget(update)
}

// target closest exit of winning subway
func targetWinningSubway(update *nw.GameUpdateMessage) {
	for _, sub := range update.Subways {
		if sub.ID == *MouseState.winSubway {
			MouseState.targetSubway = &sub
			targetClosestExit(sub, update.Player.Position)
			break
		}
	}
}

// if cat inside mouseAvoidCatRadius sets the target to opposite direction
// chooses the closest cat if multipe are inside radius
func runAwayIfCatNearby(update *nw.GameUpdateMessage) {
	var closestCat *nw.CatStateMessage
	var closestCatDist float64 = -1

	for _, cat := range update.Cats {
		d := distance(*update.Player.Position, *cat.Position)
		if closestCat == nil || (d < closestCatDist) {
			closestCatDist = d
			closestCat = &cat
		}
	}

	if closestCat != nil && closestCatDist < mouseAvoidCatRadius {
		var bestExit *nw.PositionMessage
		var bestScore float64 = -1
		
		for i := range update.Subways {
			sub := &update.Subways[i]
			isWinning := MouseState.winSubway != nil && sub.ID == *MouseState.winSubway
			
			for _, exit := range sub.Exits {
				exitPos := nw.PositionMessage{X: exit.X, Y: exit.Y}
				distToMouse := distance(*update.Player.Position, exitPos)
				distToCat := distance(*closestCat.Position, exitPos)
				
				score := distToCat - distToMouse
				if isWinning {
					score += 10000 // strongly prefer the winning subway
				}
				
				if bestExit == nil || score > bestScore {
					bestScore = score
					bestExit = &exitPos
					MouseState.targetSubway = sub
				}
			}
		}

		if bestExit != nil {
			State.target = bestExit
		}
	}
}
