import Defaults
import SwiftUI

struct PromptView: View {
  @Bindable var item: PromptDecorator
  var previous: PromptDecorator?
  var next: PromptDecorator?
  var index: Int

  private var visualIndex: Int? {
    if appState.navigator.isMultiSelectInProgress && item.selectionIndex >= 0 {
      return item.selectionIndex
    }
    return nil
  }

  private var selectionAppearance: SelectionAppearance {
    let previousSelected = previous?.isSelected ?? false
    let nextSelected = next?.isSelected ?? false
    switch (previousSelected, nextSelected) {
    case (true, false):
      return .topConnection
    case (false, true):
      return .bottomConnection
    case (true, true):
      return .topBottomConnection
    default:
      return .none
    }
  }

  @Environment(AppState.self) private var appState

  var body: some View {
    ListItemView(
      id: item.id,
      selectionId: item.id,
      attributedTitle: item.attributedTitle,
      shortcuts: item.shortcuts,
      isSelected: item.isSelected,
      selectionIndex: visualIndex,
      selectionAppearance: selectionAppearance
    ) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(verbatim: item.title).bold()
          ForEach(item.item.tags, id: \.self) { tag in
            Text(verbatim: tag)
              .font(.system(size: 10))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.secondary.opacity(0.15))
              .clipShape(Capsule())
          }
        }
        Text(verbatim: item.item.content.prefix(80).trimmingCharacters(in: .whitespacesAndNewlines) + (item.item.content.count > 80 ? "..." : ""))
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      .padding(.vertical, 4)
    }
    .onTapGesture {
      appState.promptStore.select(item)
      appState.triggerToast(message: NSLocalizedString("Copied!", comment: ""))
    }
  }
}
