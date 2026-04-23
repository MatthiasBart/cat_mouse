import Foundation 

public class Cat: Player {
    public var id: Int64 = -1
    var name: String = ""
    var position: Position = .base
    var caught: [Mouse.ID] = []
    private var type = "live"
}

class GhostCat: Cat {
    private var type = "ghost"
    var lastSeen: Date = Date()

    init(from cat: Cat) {
        super.init()
        self.id = cat.id
        self.name = cat.name
        self.position = cat.position
        self.lastSeen = Date()
    }
}
