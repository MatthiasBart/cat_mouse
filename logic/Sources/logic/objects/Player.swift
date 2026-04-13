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
}
