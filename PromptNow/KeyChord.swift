import AppKit.NSEvent
import KeyboardShortcuts
import Sauce

enum KeyChord: CaseIterable {
  static var deleteKey: Key? { Sauce.shared.key(shortcut: .delete) }
  static var deleteModifiers: NSEvent.ModifierFlags? { KeyboardShortcuts.Shortcut(name: .delete)?.modifiers }

  static var previewKey: Key? { Sauce.shared.key(shortcut: .togglePreview) }
  static var previewModifiers: NSEvent.ModifierFlags? { KeyboardShortcuts.Shortcut(name: .togglePreview)?.modifiers }

  case clearSearch
  case deleteCurrentItem
  case deleteOneCharFromSearch
  case deleteLastWordFromSearch
  case ignored
  case moveToNext
  case moveToPrevious
  case moveToFirst
  case openPreferences
  case selectCurrentItem
  case close
  case togglePreview
  case unknown

  init(_ event: NSEvent?) {
    guard let event, event.type == .keyDown else {
      self = .unknown
      return
    }

    let modifierFlags = event.modifierFlags
      .intersection(.deviceIndependentFlagsMask)
      .subtracting([.capsLock, .numericPad, .function])
    var key: Key?

    if KeyboardLayout.current.commandSwitchesToQWERTY, modifierFlags.contains(.command) {
      key = Key(QWERTYKeyCode: Int(event.keyCode))
    } else {
      key = Sauce.shared.key(for: Int(event.keyCode))
    }

    guard let key else {
      self = .unknown
      return
    }

    self.init(key, modifierFlags)
  }

  init(_ key: Key, _ modifierFlags: NSEvent.ModifierFlags) {
    switch (key, modifierFlags) {
    case (.u, [.control]):
      self = .clearSearch
    case (KeyChord.deleteKey, KeyChord.deleteModifiers):
      self = .deleteCurrentItem
    case (.h, [.control]):
      self = .deleteOneCharFromSearch
    case (.w, [.control]):
      self = .deleteLastWordFromSearch
    case (.downArrow, []),
         (.n, [.control]),
         (.j, [.control]):
      self = .moveToNext
    case (.upArrow, []),
         (.p, [.control]),
         (.k, [.control]):
      self = .moveToPrevious
    case (.upArrow, [.command, .shift]),
         (.upArrow, [.option, .shift]),
         (.p, [.control, .option, .shift]):
      self = .moveToFirst
    case (.upArrow, _) where modifierFlags.contains(.command) || modifierFlags.contains(.option),
         (.p, [.control, .option]),
         (.pageUp, []):
      self = .moveToFirst
    case (.comma, [.command]):
      self = .openPreferences
    case (.return, _),
         (.keypadEnter, _):
      self = .selectCurrentItem
    case (.escape, _):
      self = .close
    case (KeyChord.previewKey, KeyChord.previewModifiers):
      self = .togglePreview
    case (_, _) where !modifierFlags.isDisjoint(with: [.command, .control, .option]):
      self = .ignored
    default:
      self = .unknown
    }
  }
}
