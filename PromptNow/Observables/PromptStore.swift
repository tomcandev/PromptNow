import AppKit
import Defaults
import Foundation
import Logging
import Observation
import SwiftData

@Observable
class PromptStore {
  static let shared = PromptStore()
  let logger = Logger(label: "com.tomcandev.promptnow")

  var items: [PromptDecorator] = []
  var all: [PromptDecorator] = []
  var searchQuery: String = "" {
    didSet {
      updateFilteredItems()
    }
  }

  init() {
    Task {
      await PromptSeedingService.shared.seedAndSync(context: Storage.shared.context)
      try? await load()
    }
  }

  @MainActor
  func load() async throws {
    let descriptor = FetchDescriptor<Prompt>(
      sortBy: [
        SortDescriptor<Prompt>(\.title, order: .forward)
      ]
    )
    let results = try Storage.shared.context.fetch(descriptor)
    let sortedResults = results.sorted { p1, p2 in
      if p1.isFavorite == p2.isFavorite {
        return p1.title.localizedStandardCompare(p2.title) == .orderedAscending
      }
      return p1.isFavorite
    }
    all = sortedResults.map { PromptDecorator($0) }
    items = all
    AppState.shared.popup.needsResize = true
  }

  @MainActor
  func insert(_ item: Prompt) async throws {
    Storage.shared.context.insert(item)
    try Storage.shared.context.save()
    try await load()
  }

  @MainActor
  func delete(_ item: PromptDecorator) {
    Storage.shared.context.delete(item.item)
    try? Storage.shared.context.save()
    Task {
      try? await load()
    }
  }

  @MainActor
  func select(_ item: PromptDecorator) {
    Clipboard.shared.copy(item.item.content)
  }

  private func updateFilteredItems() {
    if searchQuery.isEmpty {
      items = all
    } else {
      items = all.filter { decorator in
        decorator.item.title.localizedCaseInsensitiveContains(searchQuery) ||
        decorator.item.content.localizedCaseInsensitiveContains(searchQuery) ||
        decorator.item.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
      }
    }
    AppState.shared.popup.needsResize = true
  }
}
