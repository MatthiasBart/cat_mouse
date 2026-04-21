enum Role: String, Codable, CaseIterable {
  case mouse = "MOUSE"
  case cat = "CAT"

  static var random: Role {
    return Self.allCases.randomElement()!
  }

  static func parse(apiValue: String?) -> Role? {
    guard let apiValue else {
      return nil
    }

    switch apiValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
    case "CAT":
      return .cat
    case "MOUSE":
      return .mouse
    default:
      return nil
    }
  }
}
