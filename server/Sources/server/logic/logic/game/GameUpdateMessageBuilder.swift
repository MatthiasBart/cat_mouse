import Foundation

class GameUpdateMessageBuilder {
    private var message = GameUpdateMessage()

    func mice(_ mice: [Mouse]) -> Self {
        message.mice = mice.map { MouseDTO(id: $0.id, name: $0.name, position: $0.position) }
        return self
    }

    func cats(_ cats: [Cat]) -> Self {
        message.cats = cats.map { CatDTO(id: $0.id, name: $0.name, position: $0.position, type: "live") }
        return self
    }

    func cats(_ ghostCats: [GhostCat]) -> Self {
        message.cats = ghostCats.map { CatDTO(id: $0.id, name: $0.name, position: $0.position, type: "ghost") }
        return self
    }

    func subways(_ subways: [Subway], hideSubways: Bool = false) -> Self {
    message.subways = subways.map { subway in
        GameUpdateSubwayDTO(
            id: hideSubways ? -1 : subway.id,
            exits: subway.exits.map {
                GameUpdateExitDTO(
                    id: $0.id,
                    x: $0.position.x,
                    y: $0.position.y
                )
            }
        )
    }
        return self
    }

    func fieldSize(width: Int64, height: Int64) -> Self {
    message.fieldSize = GameUpdateFieldSizeDTO(width: width, height: height)
    return self
}

    func player(_ cat: Cat) -> Self {
        message.player = PlayerDTO(cat: cat)
        return self
    }

    func player(_ mouse: Mouse) -> Self {
        message.player = PlayerDTO(mouse: mouse)
        return self
    }

    func voting(_ voting: Voting?, allSubways: [Subway]) -> Self {
        if let voting = voting {
            message.activeVote = GameUpdateVotingDTO(voting: voting, allSubways: allSubways)
        }
        return self
    }

    func timeLeft(_ time: TimeInterval) -> Self { 
        message.timeLeft = Int64(time)
        return self
    }

    func build() throws -> GameUpdateMessage {
        return message
    }
}

