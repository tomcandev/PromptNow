import Foundation
import SwiftData

class PromptSeedingService {
  static let shared = PromptSeedingService()

  private let fileManager = FileManager.default
  private let appSupportURL = URL.applicationSupportDirectory.appending(path: "PromptNow")
  private var promptsJSONURL: URL {
    appSupportURL.appending(path: "prompts.json")
  }

  /// Intelligently seeds and syncs prompts.
  /// - Built-in prompts are upserted (inserted if new, content updated if changed).
  /// - User-owned prompts are NEVER touched.
  /// - User's isFavorite on built-in prompts is preserved.
  func seedAndSync(context: ModelContext) async {
    ensureDirectoryExists()

    // Always upsert built-in prompts from the hardcoded defaults.
    // This ensures users always get the latest system prompts on app update.
    let defaults = createDefaultPrompts()
    await upsertBuiltInPrompts(defaults, context: context)

    // Also sync any prompts from the JSON file (user-added via file editing)
    syncFromJSONFile(context: context)
  }

  /// Upserts built-in prompts: inserts new ones, updates existing ones (content/tags),
  /// but never overwrites user changes to isFavorite.
  @MainActor
  private func upsertBuiltInPrompts(_ defaults: [Prompt], context: ModelContext) {
    do {
      let descriptor = FetchDescriptor<Prompt>()
      let existingPrompts = try context.fetch(descriptor)
      let existingByBuiltInID = Dictionary(
        uniqueKeysWithValues: existingPrompts.compactMap { prompt -> (String, Prompt)? in
          guard let bid = prompt.builtInID else { return nil }
          return (bid, prompt)
        }
      )

      for defaultPrompt in defaults {
        guard let builtInID = defaultPrompt.builtInID else { continue }

        if let existing = existingByBuiltInID[builtInID] {
          // Update content and tags from the latest defaults,
          // but preserve user's isFavorite choice.
          existing.title = defaultPrompt.title
          existing.content = defaultPrompt.content
          existing.tags = defaultPrompt.tags
          existing.category = defaultPrompt.category
          existing.updatedAt = Date.now
          // NOTE: existing.isFavorite is NOT overwritten — user's choice is sacred.
        } else {
          // Brand new system prompt — insert it.
          context.insert(defaultPrompt)
        }
      }

      try context.save()
      print("PromptNow: Successfully upserted \(defaults.count) built-in prompts.")
    } catch {
      print("PromptNow: Failed to upsert built-in prompts: \(error.localizedDescription)")
    }
  }

  /// Syncs user-added prompts from the JSON file (for power users who edit the file directly).
  /// Only inserts prompts whose IDs don't already exist in the database.
  private func syncFromJSONFile(context: ModelContext) {
    guard fileManager.fileExists(atPath: promptsJSONURL.path) else { return }

    do {
      let data = try Data(contentsOf: promptsJSONURL)
      let decoder = JSONDecoder()
      let wrapper = try decoder.decode(PromptWrapper.self, from: data)

      let descriptor = FetchDescriptor<Prompt>()
      let existingPrompts = try context.fetch(descriptor)
      let existingIDs = Set(existingPrompts.map { $0.id })

      var insertedCount = 0
      for prompt in wrapper.prompts {
        if !existingIDs.contains(prompt.id) {
          // Mark JSON-imported prompts as user-owned (not built-in)
          prompt.isBuiltIn = false
          prompt.builtInID = nil
          context.insert(prompt)
          insertedCount += 1
        }
      }

      if insertedCount > 0 {
        try context.save()
        print("PromptNow: Imported \(insertedCount) new prompts from JSON file.")
      }
    } catch {
      print("PromptNow: Failed to sync from JSON: \(error.localizedDescription)")
    }
  }

  private func ensureDirectoryExists() {
    if !fileManager.fileExists(atPath: appSupportURL.path) {
      try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
    }
  }

  // MARK: - Default Built-In Prompts (from awesome-chatgpt-prompts, CC0-1.0)

  private func createDefaultPrompts() -> [Prompt] {
    return [
      Prompt(
        title: "Act as a Linux Terminal",
        content: """
        I want you to act as a linux terminal. I will type commands and you will reply with what the terminal should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is pwd
        """,
        tags: ["dev", "linux", "terminal"],
        category: "Development",
        isFavorite: true,
        isBuiltIn: true,
        builtInID: "awesome-linux-terminal"
      ),
      Prompt(
        title: "Act as an English Translator",
        content: """
        I want you to act as an English translator, spelling corrector and improver. I will speak to you in any language and you will detect the language, translate it and answer in the corrected and improved version of my text, in English. I want you to replace my simplified A0-level words and sentences with more beautiful and elegant, upper level English words and sentences. Keep the meaning same, but make them more literary. I want you to only reply the correction, the improvements and nothing else, do not write explanations. My first sentence is "istanbulu cok seviyom burada olmak cok guzel"
        """,
        tags: ["translation", "english", "writing"],
        category: "Language",
        isFavorite: true,
        isBuiltIn: true,
        builtInID: "awesome-english-translator"
      ),
      Prompt(
        title: "Act as an Interviewer",
        content: """
        I want you to act as an interviewer. I will be the candidate and you will ask me the interview questions for the position. I want you to only reply as the interviewer. Do not write all the conservation at once. I want you to only do the interview with me. Ask me the questions and wait for my answers. Do not write explanations. Ask me the questions one by one like an interviewer does and wait for my answers. My first sentence is "Hi"
        """,
        tags: ["career", "interview", "hr"],
        category: "Career",
        isBuiltIn: true,
        builtInID: "awesome-interviewer"
      ),
      Prompt(
        title: "Act as a JavaScript Console",
        content: """
        I want you to act as a javascript console. I will type commands and you will reply with what the javascript console should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is console.log("Hello World");
        """,
        tags: ["dev", "js", "web"],
        category: "Development",
        isBuiltIn: true,
        builtInID: "awesome-javascript-console"
      ),
      Prompt(
        title: "Act as an Excel Sheet",
        content: """
        I want you to act as a text based excel. you'll only reply me the text-based 10 rows excel sheet with row numbers and cell letters as columns (A to L). First column header should be empty to reference row number. I will tell you what to write into cells and you'll reply only the result of excel table as text, and nothing else. Do not write explanations. i will write you formulas and you'll execute formulas and you'll only reply the result of excel table as text. First, reply me the empty sheet.
        """,
        tags: ["data", "excel", "sheets"],
        category: "Productivity",
        isBuiltIn: true,
        builtInID: "awesome-excel-sheet"
      ),
      Prompt(
        title: "Act as a Prompt Generator",
        content: """
        I want you to act as a prompt generator. Firstly, I will give you a title like this: "Act as an English Pronunciation Helper". Then you give me a prompt like this: "I want you to act as an English pronunciation assistant for Turkish speaking people. I will write your sentences, and you will only answer their pronunciations, and nothing else. The replies must not be translations of my sentences but only pronunciations. Pronunciations should use Turkish Latin letters for phonetics. Do not write explanations on replies. My first sentence is "how the weather is in Istanbul?"." (You should adapt the sample prompt according to the title I gave. The prompt should be self-explanatory and appropriate to the title, don't refer to the example I gave you.). My first title is "Act as a Code Review Helper"
        """,
        tags: ["ai", "prompts", "meta"],
        category: "AI",
        isBuiltIn: true,
        builtInID: "awesome-prompt-generator"
      ),
      Prompt(
        title: "Act as a UX/UI Developer",
        content: """
        I want you to act as a UX/UI developer. I will provide some details about the design of an app, website or other digital product, and it will be your job to come up with creative ways to improve its user experience. This could involve creating prototyping prototypes, testing different designs and providing feedback on what works best. My first request is "I need help designing a navigation system for my new mobile application."
        """,
        tags: ["design", "ux", "ui"],
        category: "Design",
        isBuiltIn: true,
        builtInID: "awesome-ux-ui-developer"
      )
    ]
  }
}

struct PromptWrapper: Codable {
  let version: String
  let prompts: [Prompt]
}
