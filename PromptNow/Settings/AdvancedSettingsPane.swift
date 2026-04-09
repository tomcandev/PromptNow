import SwiftUI
import Defaults

struct AdvancedSettingsPane: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Advanced settings will be available in the future.", tableName: "AdvancedSettings")
        .foregroundStyle(.secondary)
    }
    .frame(minWidth: 350, maxWidth: 450)
    .padding()
  }
}

#Preview {
  AdvancedSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
