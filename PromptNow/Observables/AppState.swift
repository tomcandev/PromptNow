import AppKit
import Defaults
import Foundation
import Settings
import SwiftUI

@Observable
final class AppState: Sendable {
  static let shared = AppState(promptStore: PromptStore.shared, footer: Footer())

  let multiSelectionEnabled = false

  var appDelegate: AppDelegate?
  var popup: Popup
  var promptStore: PromptStore
  var footer: Footer
  var navigator: NavigationManager
  var preview: SlideoutController
  var toastMessage: String = ""
  var showToast: Bool = false

  var searchVisible: Bool {
    if !Defaults[.showSearch] { return false }
    switch Defaults[.searchVisibility] {
    case .always: return true
    case .duringSearch: return !promptStore.searchQuery.isEmpty
    }
  }

  var menuIconText: String {
    let title = promptStore.items.first?.item.content.shortened(to: 100)
      .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
    var mutableTitle = title
    mutableTitle.unicodeScalars.removeAll(where: CharacterSet.newlines.contains)
    return mutableTitle.shortened(to: 20)
  }

  private let about = About()
  private var settingsWindowController: SettingsWindowController?

  init(promptStore: PromptStore, footer: Footer) {
    self.promptStore = promptStore
    self.footer = footer
    popup = Popup()
    navigator = NavigationManager(promptStore: promptStore, footer: footer)
    preview = SlideoutController(
      onContentResize: { contentWidth in
        Defaults[.windowSize].width = contentWidth
      },
      onSlideoutResize: { previewWidth in
        Defaults[.previewWidth] = previewWidth
      })
    preview.contentWidth = Defaults[.windowSize].width
    preview.slideoutWidth = Defaults[.previewWidth]
  }

  @MainActor
  func select() {
    if !navigator.selection.isEmpty {
      promptStore.select(navigator.selection.first!)
      triggerToast(message: NSLocalizedString("Copied!", comment: ""))
    } else if let item = footer.selectedItem {
      // TODO: Use item.suppressConfirmation, but it's not updated!
      if item.confirmation != nil, Defaults[.suppressClearAlert] == false {
        item.showConfirmation = true
      } else {
        item.action()
      }
    } else {
      Clipboard.shared.copy(promptStore.searchQuery)
      triggerToast(message: NSLocalizedString("Copied search query!", comment: ""))
      promptStore.searchQuery = ""
    }
  }

  @MainActor
  func triggerToast(message: String) {
    toastMessage = message
    showToast = true
    Task {
      try? await Task.sleep(for: .seconds(1.5))
      showToast = false
      popup.close()
    }
  }

  @MainActor
  func deleteSelection() {
    navigator.selection.forEach { _, item in
      promptStore.delete(item)
    }
  }

  @MainActor
  func editSelection() {
    if let item = navigator.selection.first {
      NSApp.activate(ignoringOtherApps: true)
      promptStore.editOrClone(item)
    }
  }

  @MainActor
  func createNewPrompt() {
    NSApp.activate(ignoringOtherApps: true)
    promptStore.createNew()
  }

  @MainActor
  func toggleFavoriteSelection() {
    if let item = navigator.selection.first {
      promptStore.toggleFavorite(item)
      triggerToast(message: item.item.isFavorite
        ? NSLocalizedString("⭐ Favorited!", comment: "")
        : NSLocalizedString("Unfavorited", comment: ""))
    }
  }

  func openAbout() {
    about.openAbout(nil)
  }

  @MainActor
  func openPreferences() { // swiftlint:disable:this function_body_length
    if settingsWindowController == nil {
      settingsWindowController = SettingsWindowController(
        panes: [
          Settings.Pane(
            identifier: Settings.PaneIdentifier.general,
            title: NSLocalizedString("Title", tableName: "GeneralSettings", comment: ""),
            toolbarIcon: NSImage.gearshape!
          ) {
            GeneralSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.storage,
            title: NSLocalizedString("Title", tableName: "StorageSettings", comment: ""),
            toolbarIcon: NSImage.externaldrive!
          ) {
            StorageSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.appearance,
            title: NSLocalizedString("Title", tableName: "AppearanceSettings", comment: ""),
            toolbarIcon: NSImage.paintpalette!
          ) {
            AppearanceSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.advanced,
            title: NSLocalizedString("Title", tableName: "AdvancedSettings", comment: ""),
            toolbarIcon: NSImage.gearshape2!
          ) {
            AdvancedSettingsPane()
          }
        ]
      )
    }
    settingsWindowController?.show()
    settingsWindowController?.window?.orderFrontRegardless()
  }

  func quit() {
    NSApp.terminate(self)
  }
}
