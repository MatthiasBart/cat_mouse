type VoteDecisionMessage = {
  type: "VOTE_DECISION";
  target_subway_id_vote: number;
};
type StartVoteMessage = {
  type: "START_VOTE";
};

// Handle player actively making a decision by voting for a subway
export function handlePlayerVote(subwayId: number, ws: WebSocket) {
  const payload: VoteDecisionMessage = {
    type: "VOTE_DECISION",
    target_subway_id_vote: subwayId,
  };

  ws.send(JSON.stringify(payload));
}

export function handleStartPlayerVote(ws: WebSocket) {
  const payload: StartVoteMessage = {
    type: "START_VOTE",
  };

  ws.send(JSON.stringify(payload));
}
