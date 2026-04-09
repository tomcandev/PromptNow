import AppKit.NSEvent
import Defaults

enum PromptAction {
  case unknown
  case copy
  case delete

  init(_ modifierFlags: NSEvent.ModifierFlags) {
    switch modifierFlags {
    case .command:
      self = .copy
    case .option:
      self = .delete
    default:
      self = .unknown
    }
  }

  var modifierFlags: NSEvent.ModifierFlags {
    switch self {
    case .copy:
      return .command
    case .delete:
      return .option
    default:
      return []
    }
  }
}
