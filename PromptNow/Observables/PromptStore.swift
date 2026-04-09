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

  // Tracks the prompt currently being edited (non-nil opens the edit sheet)
  var editingPrompt: Prompt?

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
    let sortedResults = sortWithFavoritesFirst(results)
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

  // MARK: - Favorite Toggle

  @MainActor
  func toggleFavorite(_ item: PromptDecorator) {
    item.item.isFavorite.toggle()
    try? Storage.shared.context.save()
    // Re-sort the list to reflect the new favorite status
    let allSorted = sortWithFavoritesFirst(all.map { $0.item })
    all = allSorted.map { PromptDecorator($0) }
    updateFilteredItems()
  }

  // MARK: - Clone & Edit

  /// Initiates editing a prompt.
  /// - If the prompt is built-in (system), it clones it first, then opens the clone for editing.
  /// - If the prompt is user-owned, it opens it directly for editing.
  @MainActor
  func editOrClone(_ decorator: PromptDecorator) {
    let prompt = decorator.item

    if prompt.isBuiltIn {
      // Clone the system prompt into a user-owned copy
      let clone = Prompt(
        shortID: PromptStore.generateShortID(isBuiltIn: false, category: prompt.category, title: "\(prompt.title) Copy"),
        title: "\(prompt.title) Copy",
        content: prompt.content,
        tags: prompt.tags,
        category: prompt.category,
        isFavorite: prompt.isFavorite,
        isBuiltIn: false,
        builtInID: nil,
        createdAt: Date.now,
        updatedAt: Date.now
      )
      Storage.shared.context.insert(clone)
      try? Storage.shared.context.save()
      editingPrompt = clone
    } else {
      editingPrompt = prompt
    }
  }

  /// Saves changes to the prompt being edited
  @MainActor
  func saveEdit(title: String, content: String, tags: [String], category: String) {
    guard let prompt = editingPrompt else { return }
    prompt.title = title
    prompt.content = content
    prompt.tags = tags
    prompt.category = category
    prompt.updatedAt = Date.now
    try? Storage.shared.context.save()
    editingPrompt = nil
    Task {
      try? await load()
    }
  }

  @MainActor
  func cancelEdit() {
    // If we were editing a brand-new clone that hasn't been saved yet,
    // we should consider deleting it. But since we already inserted and saved
    // it during clone, it's better to keep it — user can always delete later.
    editingPrompt = nil
  }

  // MARK: - Private Helpers

  /// Generates a semantic slug ID like "cus-marketing-seo" logic.
  static func generateShortID(isBuiltIn: Bool, category: String, title: String) -> String {
    let prefix = isBuiltIn ? "sys" : "cus"
    let safeCategory = category.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "-", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    let safeTitle = title.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "-", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    
    // Fallbacks if strings were empty after regex
    let catPart = safeCategory.isEmpty ? "gen" : String(safeCategory.prefix(10))
    let titlePart = safeTitle.isEmpty ? "prompt" : String(safeTitle.prefix(20))
    
    // e.g. "sys-dev-act-as-linux-terminal"
    return "\(prefix)-\(catPart)-\(titlePart)".replacingOccurrences(of: "--", with: "-")
  }

  private func updateFilteredItems() {
    if searchQuery.isEmpty {
      items = all
    } else {
      let filtered = all.filter { decorator in
        decorator.shortID.localizedCaseInsensitiveContains(searchQuery) ||
        decorator.item.title.localizedCaseInsensitiveContains(searchQuery) ||
        decorator.item.content.localizedCaseInsensitiveContains(searchQuery) ||
        decorator.item.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
      }
      
      // We want an exact or prefix match on shortID to float to the very top,
      // above even favorites if a user explicitly searched for an ID.
      let sortedBySearch = filtered.sorted { d1, d2 in
        let match1 = d1.shortID.localizedCaseInsensitiveContains(searchQuery)
        let match2 = d2.shortID.localizedCaseInsensitiveContains(searchQuery)
        
        if match1 && !match2 { return true }
        if !match1 && match2 { return false }
        
        // Otherwise fallback to favorites -> alphabetical
        if d1.item.isFavorite != d2.item.isFavorite {
          return d1.item.isFavorite
        }
        return d1.item.title.localizedStandardCompare(d2.item.title) == .orderedAscending
      }
      
      items = sortedBySearch
    }
    AppState.shared.popup.needsResize = true
  }

  /// Sorts prompts: favorites first, then alphabetical by title.
  private func sortWithFavoritesFirst(_ prompts: [Prompt]) -> [Prompt] {
    return prompts.sorted { p1, p2 in
      if p1.isFavorite != p2.isFavorite {
        return p1.isFavorite
      }
      return p1.title.localizedStandardCompare(p2.title) == .orderedAscending
    }
  }

  /// Same sort logic but for decorators.
  private func sortDecoratorsWithFavoritesFirst(_ decorators: [PromptDecorator]) -> [PromptDecorator] {
    return decorators.sorted { d1, d2 in
      if d1.item.isFavorite != d2.item.isFavorite {
        return d1.item.isFavorite
      }
      return d1.item.title.localizedStandardCompare(d2.item.title) == .orderedAscending
    }
  }
}
