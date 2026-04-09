import Defaults
import SwiftUI

struct PromptListView: View {
  @Binding var searchQuery: String
  @FocusState.Binding var searchFocused: Bool

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase

  @Default(.showFooter) private var showFooter

  private var items: [PromptDecorator] {
    appState.promptStore.items.filter(\.isVisible)
  }

  private var topPadding: CGFloat {
    return Popup.verticalSeparatorPadding
  }

  private var bottomPadding: CGFloat {
    return showFooter
      ? Popup.verticalSeparatorPadding
      : (Popup.verticalSeparatorPadding - 1)
  }

  var body: some View {
    VStack(spacing: 0) {
      // PromptNow: Removed PasteStack and Pins from the list view
    }
    .padding(.top, 0)
    .readHeight(appState, into: \.popup.extraTopHeight)

    ScrollView {
      ScrollViewReader { proxy in
        VStack(spacing: 0) {
          ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            PromptView(item: item, previous: index > 0 ? items[index - 1] : nil, next: index < items.count - 1 ? items[index + 1] : nil, index: index)
            
            // Add a separator below the last favorited item
            if item.item.isFavorite, index < items.count - 1, !items[index + 1].item.isFavorite {
              Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
          }
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .task(id: appState.navigator.scrollTarget) {
          guard appState.navigator.scrollTarget != nil else { return }

          try? await Task.sleep(for: .milliseconds(10))
          guard !Task.isCancelled else { return }

          if let selection = appState.navigator.scrollTarget {
            proxy.scrollTo(selection)
            appState.navigator.scrollTarget = nil
          }
        }
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            searchFocused = true
            appState.navigator.isKeyboardNavigating = true
            appState.navigator.select(item: appState.promptStore.items.first)
            appState.preview.enableAutoOpen()
            appState.preview.resetAutoOpenSuppression()
            appState.preview.startAutoOpen()
          } else {
            modifierFlags.flags = []
            appState.navigator.isKeyboardNavigating = true
            appState.preview.cancelAutoOpen()
          }
        }
        .background {
          GeometryReader { geo in
            Color.clear
              .task(id: appState.popup.needsResize) {
                try? await Task.sleep(for: .milliseconds(10))
                guard !Task.isCancelled else { return }

                if appState.popup.needsResize {
                  appState.popup.resize(height: geo.size.height)
                }
              }
          }
        }
      }
      .contentMargins(.leading, 10, for: .scrollIndicators)
      .contentMargins(.top, topPadding, for: .scrollIndicators)
      .contentMargins(.bottom, bottomPadding, for: .scrollIndicators)
    }

    VStack(spacing: 0) {
      // PromptNow: Removed bottom pins
    }
    .padding(.bottom, 0)
    .readHeight(appState, into: \.popup.extraBottomHeight)
  }
}
