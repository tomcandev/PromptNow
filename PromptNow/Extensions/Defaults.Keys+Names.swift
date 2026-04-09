import AppKit
import Defaults

extension Defaults.Keys {
  static let highlightMatch = Key<HighlightMatch>("highlightMatch", default: .bold)
  static let lastReviewRequestedAt = Key<Date>("lastReviewRequestedAt", default: Date.now)
  static let numberOfUsages = Key<Int>("numberOfUsages", default: 0)
  static let popupPosition = Key<PopupPosition>("popupPosition", default: .cursor)
  static let popupScreen = Key<Int>("popupScreen", default: 0)
  static let previewDelay = Key<Int>("previewDelay", default: 1500)
  static let showFooter = Key<Bool>("showFooter", default: true)
  static let showInStatusBar = Key<Bool>("showInStatusBar", default: true)
  static let showSearch = Key<Bool>("showSearch", default: true)
  static let searchVisibility = Key<SearchVisibility>("searchVisibility", default: .always)
  static let showTitle = Key<Bool>("showTitle", default: true)
  static let size = Key<Int>("historySize", default: 200)
  static let suppressClearAlert = Key<Bool>("suppressClearAlert", default: false)
  static let windowSize = Key<NSSize>("windowSize", default: NSSize(width: 450, height: 800))
  static let windowPosition = Key<NSPoint>("windowPosition", default: NSPoint(x: 0.5, y: 0.8))
  static let previewWidth = Key<CGFloat>("previewWidth", default: 400)
}
