import Foundation

protocol Player: AnyObject, Identifiable, Movable, Encodable {
    var id: Int64 { get set }
    var name: String { get set } 
}

class PlayerDTO: Player {
    var id: Int64
        var name: String
        var role: String
        var subway: Int64?
        var position: Position

        init(
                id: Int64, 
                name: String, 
                role: String, 
                subway: Int64?,
                position: Position
            ) {
            self.id = id 
                self.name = name
                self.role = role
                self.subway = subway
                self.position = position
        }

        convenience init(cat: Cat) { 
            self.init(
            id: cat.id,
            name: cat.name,
            role: "cat",
            subway: nil,
            position: cat.position
        )
        }

        convenience init(mouse: Mouse) { 
            self.init(
            id: mouse.id,
            name: mouse.name,
            role: "mouse",
            subway: mouse.subway,
            position: mouse.position
        )
        }
}
