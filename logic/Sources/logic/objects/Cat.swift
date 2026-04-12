class Cat: Player {
    var id: Int64 = -1
    var name: String = ""
    var position: Position = .base
    private var type = "live"
}

class GhostCat: Cat {
    private var type = "ghost"
}
