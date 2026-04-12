import Foundation

protocol Player: Identifiable, Movable {
    var id: Int64 { get set }
    var name: String { get set } 
}
