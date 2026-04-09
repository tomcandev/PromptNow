import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var appState = AppState.shared
  @State private var modifierFlags = ModifierFlags()
  @State private var scenePhase: ScenePhase = .background

  @FocusState private var searchFocused: Bool

  var body: some View {
    ZStack {
      if #available(macOS 26.0, *) {
        GlassEffectView()
      } else {
        VisualEffectView()
      }

      KeyHandlingView(searchQuery: $appState.promptStore.searchQuery, searchFocused: $searchFocused) {
        VStack(spacing: 0) {
          SlideoutView(controller: appState.preview) {
            HeaderView(
              controller: appState.preview,
              searchFocused: $searchFocused
            )

            VStack(alignment: .leading, spacing: 0) {
              PromptListView(
                searchQuery: $appState.promptStore.searchQuery,
                searchFocused: $searchFocused
              )
            }
            .animation(.default.speed(3), value: appState.promptStore.items)
            .padding(.horizontal, Popup.horizontalPadding)
            .onAppear {
              searchFocused = true
            }
            .onMouseMove {
              appState.navigator.isKeyboardNavigating = false
            }
          } slideout: {
            SlideoutContentView()
          }
          .frame(minHeight: 0)
          .layoutPriority(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .task {
        try? await appState.promptStore.load()
      }
    }
    .overlay {
      if appState.showToast {
        VStack {
          Spacer()
          Text(appState.toastMessage)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 40)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.showToast)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: appState.searchVisible)
    .environment(appState)
    .environment(modifierFlags)
    .environment(\.scenePhase, scenePhase)
    .sheet(isPresented: Binding(
      get: { appState.promptStore.editingPrompt != nil },
      set: { if !$0 { appState.promptStore.cancelEdit() } }
    )) {
      PromptEditView()
        .environment(appState)
    }
    // FloatingPanel is not a scene, so let's implement custom scenePhase..
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .active
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) {
      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .background
      }
    }
  }
}

#Preview {
  ContentView()
    .environment(\.locale, .init(identifier: "en"))
    .modelContainer(Storage.shared.container)
}
