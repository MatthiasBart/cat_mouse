import Foundation

class GameStateDTOBuilder {
    private var dto = GameStateDTO()

    func mice(_ mice: [Mouse]) -> Self {
        dto.mice = mice
        return self
    }

    func cats(_ cats: [Cat]) -> Self {
        dto.cats = cats
        return self
    }

    func player(_ player: any Player) -> Self {
        if let cat = player as? Cat {
            dto.player = PlayerDTO(cat: cat)
        } else if let mouse = player as? Mouse {
            dto.player = PlayerDTO(mouse: mouse)
        }
        return self
    }

    func voting(_ voting: Voting?) -> Self {
        dto.activeVote = voting
        return self
    }

    func timeLeft(_ time: TimeInterval) -> Self { 
        dto.timeLeft = Int64(time)
        return self
    }

    func build() throws -> Data {
        try JSONEncoder().encode(dto)
    }
}

struct GameStateDTO: Encodable { 
    var timeLeft: Int64? = nil
    var player: PlayerDTO? = nil
    var mice: [Mouse] = []
    var cats: [Cat] = []
    var activeVote: Voting? = nil
}
