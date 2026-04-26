package bot


// RunMouseLogic executes one mouse tick.
// TODO: implement mouse strategy from README (no voting for now).
func RunMouseLogic() {
	state := snapshotState()
	if state.Role != "MOUSE" {
		return
	}

	// TODO: decide mouse behavior and send WS messages directly.
}
