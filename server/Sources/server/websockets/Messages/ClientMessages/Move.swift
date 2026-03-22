struct Move: ClientMessage {
  var type: ClientMessageType { .move }
  var test: String  // TODO: replace with real data
}
