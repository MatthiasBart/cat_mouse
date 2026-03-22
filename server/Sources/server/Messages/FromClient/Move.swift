struct Move: Codable {
  var type: MessageType { .move }
  var test: String  // TODO: replace with real data
}
