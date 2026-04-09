import Foundation
import SwiftData

class PromptSeedingService {
  static let shared = PromptSeedingService()

  private let fileManager = FileManager.default
  private let appSupportURL = URL.applicationSupportDirectory.appending(path: "PromptNow")
  private var promptsJSONURL: URL {
    appSupportURL.appending(path: "prompts.json")
  }

  func seedAndSync(context: ModelContext) async {
    ensureDirectoryExists()
    ensureJSONFileExists()

    do {
      let data = try Data(contentsOf: promptsJSONURL)
      let decoder = JSONDecoder()
      let wrapper = try decoder.decode(PromptWrapper.self, from: data)

      // Simple sync for MVP: Clear and reload from JSON
      // In a more advanced version, we could do a smart merge.
      try await clearStore(context: context)
      for prompt in wrapper.prompts {
        context.insert(prompt)
      }
      try context.save()
      print("PromptNow: Successfully synced \(wrapper.prompts.count) prompts from JSON.")
    } catch {
      print("PromptNow: Failed to seed/sync prompts: \(error.localizedDescription)")
    }
  }

  private func ensureDirectoryExists() {
    if !fileManager.fileExists(atPath: appSupportURL.path) {
      try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
    }
  }

  private func ensureJSONFileExists() {
    if !fileManager.fileExists(atPath: promptsJSONURL.path) {
      let defaultPrompts = createDefaultPrompts()
      let wrapper = PromptWrapper(version: "1.0", prompts: defaultPrompts)
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      if let data = try? encoder.encode(wrapper) {
        try? data.write(to: promptsJSONURL)
      }
    }
  }

  @MainActor
  private func clearStore(context: ModelContext) async throws {
    let descriptor = FetchDescriptor<Prompt>()
    let items = try context.fetch(descriptor)
    for item in items {
      context.delete(item)
    }
  }

  private func createDefaultPrompts() -> [Prompt] {
    return [
      Prompt(
        title: "Refactoring Code",
        content: "Act as a Senior Developer. Refactor the following code to improve performance and readability. Add comments explaining the changes:\n\n```\n[Paste your code here]\n```",
        tags: ["coding", "refactor"],
        category: "Development"
      ),
      Prompt(
        title: "SEO Blog Outline",
        content: "Create a comprehensive SEO-optimized blog outline for the topic: [Topic]. Include H2 and H3 tags, suggested word count per section, and 5 relevant keywords to target.",
        tags: ["marketing", "seo", "blog"],
        category: "Marketing"
      ),
      Prompt(
        title: "Code Review Feedback",
        content: "You are a tech lead reviewing a pull request. Provide constructive feedback on the following code changes. Focus on:\n1. Code quality and readability\n2. Potential bugs\n3. Performance considerations\n4. Suggestions for improvement\n\n```\n[Paste diff here]\n```",
        tags: ["coding", "review"],
        category: "Development",
        isFavorite: true
      ),
      Prompt(
        title: "Professional Email Reply",
        content: "Draft a professional and diplomatic email reply to the following message. Maintain a positive tone while addressing all points raised:\n\n[Paste original email here]",
        tags: ["communication", "email"],
        category: "Communication"
      ),
      Prompt(
        title: "Bug Report Analysis",
        content: "Analyze the following bug report and provide:\n1. Root cause hypothesis\n2. Steps to reproduce\n3. Severity assessment (Critical/High/Medium/Low)\n4. Suggested fix approach\n5. Estimated effort\n\nBug Report:\n[Paste bug report here]",
        tags: ["qa", "debugging"],
        category: "Development"
      )
    ]
  }
}

struct PromptWrapper: Codable {
  let version: String
  let prompts: [Prompt]
}
