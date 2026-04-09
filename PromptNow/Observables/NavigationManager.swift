import Foundation
import SwiftUI

@Observable
class NavigationManager {
  private var promptStore: PromptStore
  private var footer: Footer

  init(promptStore: PromptStore, footer: Footer) {
    self.promptStore = promptStore
    self.footer = footer
  }

  var selection: Selection<PromptDecorator> = Selection() {
    willSet {
      selection.forEach { _, item in item.selectionIndex = -1 }
      newValue.forEach { index, item in item.selectionIndex = index }
    }
  }

  var scrollTarget: UUID?
  var leadSelection: UUID? {
    if let item = leadPrompt {
      return item.id
    }
    if let footerItem = footer.selectedItem {
      return footerItem.id
    }
    return nil
  }
  private(set) var leadPrompt: PromptDecorator? {
    didSet {
      guard oldValue?.id != leadPrompt?.id else { return }

      let preview = AppState.shared.preview
      if leadPrompt != nil {
        preview.resetAutoOpenSuppression()
        preview.startAutoOpen()
      } else {
        preview.cancelAutoOpen()
      }
    }
  }

  var isManualMultiSelect: Bool = false
  var isMultiSelectInProgress: Bool {
    return isManualMultiSelect || selection.count > 1
  }

  var hoverSelectionWhileKeyboardNavigating: UUID?
  var isKeyboardNavigating: Bool = true

  func select(id: UUID) {
    if let item = promptStore.items.first(where: { $0.id == id }) {
      select(item: item, footerItem: nil)
    } else if let item = footer.items.first(where: { $0.id == id }) {
      select(item: nil, footerItem: item)
    } else {
      select(item: nil, footerItem: nil)
    }
  }

  func selectWithoutScrolling(id: UUID) {
    if let item = promptStore.items.first(where: { $0.id == id }) {
      selectWithoutScrolling(item: item, footerItem: nil)
    } else if let item = footer.items.first(where: { $0.id == id }) {
      selectWithoutScrolling(item: nil, footerItem: item)
    } else {
      selectWithoutScrolling(item: nil, footerItem: nil)
    }
  }

  func select(item: PromptDecorator? = nil, footerItem: FooterItem? = nil) {
    withTransaction(Transaction()) {
      selectWithoutScrolling(item: item, footerItem: footerItem)
      scrollTarget = item?.id ?? footerItem?.id
    }
  }

  func selectWithoutScrolling(item: PromptDecorator? = nil, footerItem: FooterItem? = nil) {
    if let item = item {
      leadPrompt = item
      selection = .init(items: [item])
      footer.selectedItem = nil
    } else if let footerItem = footerItem {
      leadPrompt = nil
      selection = .init()
      footer.selectedItem = footerItem
    } else {
      leadPrompt = nil
      selection = .init()
      footer.selectedItem = nil
    }
  }

  func highlightFirst() {
    if let item = promptStore.items.first {
      select(item: item)
    } else {
      select(item: nil)
    }
  }

  func highlightNext() {
    guard let lead = leadPrompt else {
      highlightFirst()
      return
    }

    if let index = promptStore.items.firstIndex(of: lead),
       index < promptStore.items.count - 1 {
      select(item: promptStore.items[index + 1])
    } else if let firstFooter = footer.items.first {
      select(footerItem: firstFooter)
    }
  }

  func highlightPrevious() {
    if let lead = leadPrompt {
      if let index = promptStore.items.firstIndex(of: lead),
         index > 0 {
        select(item: promptStore.items[index - 1])
      }
    } else if let footerSelected = footer.selectedItem {
      if let index = footer.items.firstIndex(of: footerSelected),
         index > 0 {
        select(footerItem: footer.items[index - 1])
      } else if let lastPrompt = promptStore.items.last {
        select(item: lastPrompt)
      }
    }
  }
}
