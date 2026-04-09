import KeyboardShortcuts
import SwiftUI

struct PreviewItemView: View {
  var item: PromptDecorator

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView {
        Text(item.text)
          .font(.system(.body, design: .monospaced))
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Spacer(minLength: 0)

      Divider()
        .padding(.vertical)

      HStack(spacing: 3) {
        Text("Created", tableName: "PreviewItemView")
        Text(item.item.createdAt, style: .date)
        Text(item.item.createdAt, style: .time)
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .controlSize(.small)
  }
}
