import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  var panel: FloatingPanel<ContentView>!

  @objc
  private lazy var statusItem: NSStatusItem = {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.behavior = .removalAllowed
    statusItem.button?.action = #selector(performStatusItemClick)
    statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    statusItem.button?.image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "PromptNow")
    statusItem.button?.imagePosition = .imageLeft
    statusItem.button?.target = self
    return statusItem
  }()

  private lazy var contextMenu: NSMenu = {
    let menu = NSMenu()
    menu.addItem(withTitle: NSLocalizedString("preferences", comment: ""), action: #selector(openPreferences), keyEquivalent: ",")
    menu.addItem(NSMenuItem.separator())
    menu.addItem(withTitle: NSLocalizedString("about", comment: ""), action: #selector(openAbout), keyEquivalent: "")
    menu.addItem(withTitle: NSLocalizedString("quit", comment: ""), action: #selector(quitApp), keyEquivalent: "q")
    return menu
  }()

  private var statusItemVisibilityObserver: NSKeyValueObservation?

  func applicationWillFinishLaunching(_ notification: Notification) {
    #if DEBUG
    if CommandLine.arguments.contains("enable-testing") {
      SPUUpdater(hostBundle: Bundle.main,
                 applicationBundle: Bundle.main,
                 userDriver: SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil),
                 delegate: nil)
      .automaticallyChecksForUpdates = false
    }
    #endif

    AppState.shared.appDelegate = self

    statusItemVisibilityObserver = observe(\.statusItem.isVisible, options: .new) { _, change in
      if let newValue = change.newValue, Defaults[.showInStatusBar] != newValue {
        Defaults[.showInStatusBar] = newValue
      }
    }

    Task {
      for await value in Defaults.updates(.showInStatusBar) {
        statusItem.isVisible = value
      }
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    panel = FloatingPanel(
      contentRect: NSRect(origin: .zero, size: Defaults[.windowSize]),
      identifier: Bundle.main.bundleIdentifier ?? "com.tomcandev.promptnow",
      statusBarButton: statusItem.button,
      onClose: { AppState.shared.popup.reset() }
    ) {
      ContentView()
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    panel.toggle(height: AppState.shared.popup.height)
    return true
  }

  func applicationWillTerminate(_ notification: Notification) {
    // Cleanup if needed
  }

  @objc
  @MainActor
  private func openPreferences() {
    AppState.shared.openPreferences()
  }

  @objc
  @MainActor
  private func openAbout() {
    AppState.shared.openAbout()
  }

  @objc
  @MainActor
  private func quitApp() {
    AppState.shared.quit()
  }

  @objc
  private func performStatusItemClick() {
    if let event = NSApp.currentEvent,
       event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
      statusItem.menu = contextMenu
      statusItem.button?.performClick(nil)
      statusItem.menu = nil
    } else {
      panel.toggle(height: AppState.shared.popup.height, at: .statusItem)
    }
  }
}
