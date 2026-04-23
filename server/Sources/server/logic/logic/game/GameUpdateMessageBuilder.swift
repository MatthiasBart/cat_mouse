import Foundation

class GameUpdateMessageBuilder {
    private var message = GameUpdateMessage()

    func mice(_ mice: [Mouse]) -> Self {
        message.mice = mice
        return self
    }

    func cats(_ cats: [Cat]) -> Self {
        message.cats = cats
        return self
    }

    func player(_ player: any Player) -> Self {
        if let cat = player as? Cat {
            message.player = PlayerDTO(cat: cat)
        } else if let mouse = player as? Mouse {
            message.player = PlayerDTO(mouse: mouse)
        }
        return self
    }

    func voting(_ voting: Voting?) -> Self {
        message.activeVote = voting
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

