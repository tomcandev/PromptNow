import AppKit
import Defaults

enum MenuIcon: String, CaseIterable, Identifiable, Defaults.Serializable {
  case promptNow
  case clipboard
  case scissors
  case paperclip

  var id: Self { self }

  var image: NSImage {
    switch self {
    case .promptNow:
      if #available(macOS 11.0, *) {
        let config = NSImage.SymbolConfiguration(scale: .medium)
        return NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "PromptNow")?.withSymbolConfiguration(config) ?? NSImage()
      }
      return NSImage(named: .promptNowStatusBar) ?? NSImage()
    case .clipboard:
      return NSImage(named: .clipboard) ?? NSImage()
    case .scissors:
      return NSImage(named: .scissors) ?? NSImage()
    case .paperclip:
      return NSImage(named: .paperclip) ?? NSImage()
    }
  }
}
