import SwiftUI

struct PinsView: View {
  @Environment(AppState.self) private var appState

  var items: [PromptDecorator]

  var body: some View {
    MultipleSelectionListView(items: items) { previous, item, next, index in
      PromptView(item: item, previous: previous, next: next, index: index)
    }
  }
}
