import SwiftUI

struct PromptEditView: View {
  @Environment(AppState.self) private var appState

  @State private var title: String = ""
  @State private var content: String = ""
  @State private var tagsText: String = ""
  @State private var category: String = ""

  private var prompt: Prompt? {
    appState.promptStore.editingPrompt
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Edit Prompt")
          .font(.headline)
          .foregroundStyle(.primary)

        Spacer()

        Button(action: { appState.promptStore.cancelEdit() }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
            .font(.title2)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.escape, modifiers: [])
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .padding(.bottom, 12)

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Title
          VStack(alignment: .leading, spacing: 4) {
            Text("Title")
              .font(.caption)
              .foregroundStyle(.secondary)
            TextField("Prompt title...", text: $title)
              .textFieldStyle(.roundedBorder)
              .font(.body)
          }

          // Category
          VStack(alignment: .leading, spacing: 4) {
            Text("Category")
              .font(.caption)
              .foregroundStyle(.secondary)
            TextField("e.g. Development, Marketing...", text: $category)
              .textFieldStyle(.roundedBorder)
              .font(.body)
          }

          // Tags
          VStack(alignment: .leading, spacing: 4) {
            Text("Tags")
              .font(.caption)
              .foregroundStyle(.secondary)
            TextField("Comma-separated: dev, coding, refactor", text: $tagsText)
              .textFieldStyle(.roundedBorder)
              .font(.body)
          }

          // Content
          VStack(alignment: .leading, spacing: 4) {
            Text("Prompt Content")
              .font(.caption)
              .foregroundStyle(.secondary)
            TextEditor(text: $content)
              .font(.system(.body, design: .monospaced))
              .frame(minHeight: 200)
              .scrollContentBackground(.hidden)
              .padding(8)
              .background(Color(.textBackgroundColor).opacity(0.5))
              .cornerRadius(6)
              .overlay(
                RoundedRectangle(cornerRadius: 6)
                  .stroke(Color(.separatorColor), lineWidth: 0.5)
              )
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }

      Divider()

      // Footer buttons
      HStack {
        Spacer()
        Button("Cancel") {
          appState.promptStore.cancelEdit()
        }
        .keyboardShortcut(.escape, modifiers: [])

        Button("Save") {
          let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
          appState.promptStore.saveEdit(
            title: title,
            content: content,
            tags: tags,
            category: category
          )
          appState.triggerToast(message: NSLocalizedString("✅ Saved!", comment: ""))
        }
        .keyboardShortcut(.return, modifiers: .command)
        .buttonStyle(.borderedProminent)
        .disabled(title.isEmpty || content.isEmpty)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
    }
    .frame(minWidth: 520, maxWidth: 520, minHeight: 480)
    .background(.ultraThinMaterial)
    .onAppear {
      if let p = prompt {
        title = p.title
        content = p.content
        tagsText = p.tags.joined(separator: ", ")
        category = p.category
      }
    }
  }
}
