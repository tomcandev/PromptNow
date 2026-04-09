import SwiftUI

struct ListItemTitleView<Title: View>: View {
  var attributedTitle: AttributedString?
  @ViewBuilder var title: () -> Title

  var body: some View {
    title()
      .accessibilityIdentifier("copy-prompt-item")
      // Workaround for macOS 26 to avoid flipped text
      // https://github.com/p0deje/PromptNow/issues/1113
      .drawingGroup()
  }
}
