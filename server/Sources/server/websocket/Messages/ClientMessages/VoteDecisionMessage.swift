struct VoteDecisionMessage: ClientMessage {
    var type: ClientMessageType { .voteDecision }
    let target_subway_id_vote: Int64
}