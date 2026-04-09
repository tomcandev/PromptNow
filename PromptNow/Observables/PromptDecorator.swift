import AppKit
import Defaults
import Foundation
import Observation
import Sauce

@Observable
class PromptDecorator: Identifiable, Hashable, HasVisibility {
  static func == (lhs: PromptDecorator, rhs: PromptDecorator) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String = ""
  var shortID: String { item.shortID }
  var attributedTitle: AttributedString?

  var isVisible: Bool = true
  var selectionIndex: Int = -1
  var isSelected: Bool {
    return selectionIndex != -1
  }
  var shortcuts: [KeyShortcut] = []

  var text: String { item.content }

  var isPinned: Bool { item.isFavorite }
  var isUnpinned: Bool { !item.isFavorite }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
  }

  private(set) var item: Prompt

  init(_ item: Prompt, shortcuts: [KeyShortcut] = []) {
    self.item = item
    self.shortcuts = shortcuts
    self.title = item.title

    synchronizeItemTitle()
  }

  func highlight(_ query: String, _ ranges: [Range<String.Index>]) {
    guard !query.isEmpty, !title.isEmpty else {
      attributedTitle = nil
      return
    }

    var attributedString = AttributedString(title.shortened(to: 500))
    for range in ranges {
      if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
         let upperBound = AttributedString.Index(range.upperBound, within: attributedString) {
        attributedString[lowerBound..<upperBound].backgroundColor = .findHighlightColor
        attributedString[lowerBound..<upperBound].foregroundColor = .black
      }
    }

    attributedTitle = attributedString
  }

  @MainActor
  func togglePin() {
    item.isFavorite.toggle()
  }

  private func synchronizeItemTitle() {
    _ = withObservationTracking {
      item.title
    } onChange: {
      DispatchQueue.main.async {
        self.title = self.item.title
        self.synchronizeItemTitle()
      }
    }
  }
}
