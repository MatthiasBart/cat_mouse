struct VoteDecisionMessage: ClientMessage {
    var type: ClientMessageType { .voteDecision }
    let target_subway_id_vote: Int64

    func execute(on game: Game, by player: Int64) throws {
        try game.vote(subway: target_subway_id_vote, mouse: player)
    }
}
