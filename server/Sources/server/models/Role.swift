enum Role: String, Codable, CaseIterable {
  case mouse = "MOUSE"
  case cat = "CAT"

  static var random: Role {
    return Self.allCases.randomElement()!
  }
}
