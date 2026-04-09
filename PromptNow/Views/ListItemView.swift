import Defaults
import SwiftUI

enum SelectionAppearance {
  case none
  case topConnection
  case bottomConnection
  case topBottomConnection

  func rect(cornerRadius: CGFloat) -> some Shape {
    var cornerRadii = RectangleCornerRadii()
    switch self {
    case .none:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .topConnection:
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .bottomConnection:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
    case .topBottomConnection:
      break
    }
    return .rect(cornerRadii: cornerRadii)
  }
}

struct ListItemView<Title: View, ID: Hashable>: View {
  var id: ID
  var selectionId: UUID
  var attributedTitle: AttributedString?
  var shortcuts: [KeyShortcut]
  var isSelected: Bool
  var selectionIndex: Int?
  var help: LocalizedStringKey?
  var selectionAppearance: SelectionAppearance = .none
  @ViewBuilder var title: () -> Title

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  var body: some View {
    HStack(spacing: 0) {
      Spacer()
        .frame(width: 10)

      ListItemTitleView(attributedTitle: attributedTitle, title: title)
        .padding(.trailing, 5)

      Spacer()

    }
    .frame(minHeight: Popup.itemHeight)
    .id(id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(isSelected ? Color.white : .primary)
    // macOS 26 broke hovering if no background is present.
    // The slight opcaity white background is a workaround
    .background(isSelected ? Color.accentColor.opacity(0.8) : .white.opacity(0.001))
    .clipShape(selectionAppearance.rect(cornerRadius: Popup.cornerRadius))
    .hoverSelectionId(selectionId)
    .help(help ?? "")
  }
}
