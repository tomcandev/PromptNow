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
        title: "Act as a Linux Terminal",
        content: """
        I want you to act as a linux terminal. I will type commands and you will reply with what the terminal should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is pwd
        """,
        tags: ["dev", "linux", "terminal"],
        category: "Development",
        isFavorite: true
      ),
      Prompt(
        title: "Act as an English Translator",
        content: """
        I want you to act as an English translator, spelling corrector and improver. I will speak to you in any language and you will detect the language, translate it and answer in the corrected and improved version of my text, in English. I want you to replace my simplified A0-level words and sentences with more beautiful and elegant, upper level English words and sentences. Keep the meaning same, but make them more literary. I want you to only reply the correction, the improvements and nothing else, do not write explanations. My first sentence is "istanbulu cok seviyom burada olmak cok guzel"
        """,
        tags: ["translation", "english", "writing"],
        category: "Language",
        isFavorite: true
      ),
      Prompt(
        title: "Act as an Interviewer",
        content: """
        I want you to act as an interviewer. I will be the candidate and you will ask me the interview questions for the position. I want you to only reply as the interviewer. Do not write all the conservation at once. I want you to only do the interview with me. Ask me the questions and wait for my answers. Do not write explanations. Ask me the questions one by one like an interviewer does and wait for my answers. My first sentence is "Hi"
        """,
        tags: ["career", "interview", "hr"],
        category: "Career"
      ),
      Prompt(
        title: "Act as a JavaScript Console",
        content: """
        I want you to act as a javascript console. I will type commands and you will reply with what the javascript console should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is console.log("Hello World");
        """,
        tags: ["dev", "js", "web"],
        category: "Development"
      ),
      Prompt(
        title: "Act as an Excel Sheet",
        content: """
        I want you to act as a text based excel. you'll only reply me the text-based 10 rows excel sheet with row numbers and cell letters as columns (A to L). First column header should be empty to reference row number. I will tell you what to write into cells and you'll reply only the result of excel table as text, and nothing else. Do not write explanations. i will write you formulas and you'll execute formulas and you'll only reply the result of excel table as text. First, reply me the empty sheet.
        """,
        tags: ["data", "excel", "sheets"],
        category: "Productivity"
      ),
      Prompt(
        title: "Act as a Prompt Generator",
        content: """
        I want you to act as a prompt generator. Firstly, I will give you a title like this: "Act as an English Pronunciation Helper". Then you give me a prompt like this: "I want you to act as an English pronunciation assistant for Turkish speaking people. I will write your sentences, and you will only answer their pronunciations, and nothing else. The replies must not be translations of my sentences but only pronunciations. Pronunciations should use Turkish Latin letters for phonetics. Do not write explanations on replies. My first sentence is "how the weather is in Istanbul?"." (You should adapt the sample prompt according to the title I gave. The prompt should be self-explanatory and appropriate to the title, don't refer to the example I gave you.). My first title is "Act as a Code Review Helper"
        """,
        tags: ["ai", "prompts", "meta"],
        category: "AI"
      ),
      Prompt(
        title: "Act as a UX/UI Developer",
        content: """
        I want you to act as a UX/UI developer. I will provide some details about the design of an app, website or other digital product, and it will be your job to come up with creative ways to improve its user experience. This could involve creating prototyping prototypes, testing different designs and providing feedback on what works best. My first request is "I need help designing a navigation system for my new mobile application."
        """,
        tags: ["design", "ux", "ui"],
        category: "Design"
      )
    ]
  }
}

struct PromptWrapper: Codable {
  let version: String
  let prompts: [Prompt]
}
