import AppKit

class Clipboard {
  static let shared = Clipboard()

  private let pasteboard = NSPasteboard.general

  init() {}

  @MainActor
  func copy(_ string: String) {
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
  }
}
