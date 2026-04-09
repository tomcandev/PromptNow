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
          Text(verbatim: item.shortID)
            .font(.system(.caption, design: .monospaced).weight(.medium))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.teal.opacity(0.15))
            .foregroundStyle(.teal)
            .clipShape(Capsule())

          Text(verbatim: item.title)
            .font(.system(.body, design: .default).weight(.semibold))
          
          if item.item.isBuiltIn {
            Text("Built-in")
              .font(.system(size: 9, weight: .medium))
              .padding(.horizontal, 5)
              .padding(.vertical, 1)
              .background(.blue.opacity(0.15))
              .foregroundStyle(.blue)
              .clipShape(Capsule())
          }
          
          ForEach(item.item.tags, id: \.self) { tag in
            Text(verbatim: tag)
              .font(.system(size: 10))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.secondary.opacity(0.15))
              .clipShape(Capsule())
          }
          
          Spacer()
          
          // Action Buttons
          HStack(spacing: 12) {
            Button(action: {
              appState.promptStore.editOrClone(item)
            }) {
              Image(systemName: "pencil")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit/Clone (Cmd+E)")
            
            Button(action: {
              appState.promptStore.toggleFavorite(item)
              appState.triggerToast(message: item.item.isFavorite
                ? NSLocalizedString("⭐ Favorited!", comment: "")
                : NSLocalizedString("Unfavorited", comment: ""))
            }) {
              Image(systemName: item.item.isFavorite ? "star.fill" : "star")
                .font(.system(size: 11))
                .foregroundStyle(item.item.isFavorite ? .yellow.opacity(0.85) : .secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .help("Toggle Favorite (Cmd+S)")
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
