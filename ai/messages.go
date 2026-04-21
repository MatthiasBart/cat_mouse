package main

type moveMessage struct {
	Type string `json:"type"`
	Test string `json:"test"`
}

type gameUpdateMessage struct {
	Type     string `json:"type"`
	Seq      int64  `json:"seq"`
	TimeLeft int64  `json:"timeLeft"`

	Player struct {
		ID       int64  `json:"id"`
		Name     string `json:"name"`
		Role     string `json:"role"`
		Subway   *int64 `json:"subway,omitempty"`
		Position *struct {
			X int64 `json:"x"`
			Y int64 `json:"y"`
		} `json:"position,omitempty"`
	} `json:"player"`

	Mice []struct {
		ID       int64  `json:"id"`
		Name     string `json:"name"`
		Subway   *int64 `json:"subway,omitempty"`
		Position *struct {
			X int64 `json:"x"`
			Y int64 `json:"y"`
		} `json:"position,omitempty"`
	} `json:"mice"`

	Cats []struct {
		ID       int64  `json:"id"`
		Name     string `json:"name"`
		Type     string `json:"type"`
		Subway   *int64 `json:"subway,omitempty"`
		Position *struct {
			X int64 `json:"x"`
			Y int64 `json:"y"`
		} `json:"position,omitempty"`
	} `json:"cats"`

	ActiveVote *struct {
		TimeLeft int64 `json:"timeLeft"`
		Votes    []struct {
			SubwayID int64 `json:"subwayId"`
			Votes    int64 `json:"votes"`
		} `json:"votes"`
	} `json:"active_vote,omitempty"`
}
