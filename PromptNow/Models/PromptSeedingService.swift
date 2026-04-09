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

    let defaults = createDefaultPrompts()
    await upsertBuiltInPrompts(defaults, context: context)
    syncFromJSONFile(context: context)
  }

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
          existing.shortID = defaultPrompt.shortID
          existing.title = defaultPrompt.title
          existing.content = defaultPrompt.content
          existing.tags = defaultPrompt.tags
          existing.category = defaultPrompt.category
          existing.updatedAt = Date.now
        } else {
          context.insert(defaultPrompt)
        }
      }

      try context.save()
      print("PromptNow: Successfully upserted \(defaults.count) built-in prompts.")
    } catch {
      print("PromptNow: Failed to upsert built-in prompts: \(error.localizedDescription)")
    }
  }

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
          prompt.isBuiltIn = false
          prompt.builtInID = nil
          if prompt.shortID.isEmpty {
            prompt.shortID = PromptStore.generateShortID(isBuiltIn: false, category: prompt.category, title: prompt.title)
          }
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

  // MARK: - Default Built-In Prompts (20 Curated from awesome-chatgpt-prompts)

  private func createDefaultPrompts() -> [Prompt] {
    return [
      Prompt(
        shortID: "sys-dev-linux",
        title: "Act as a Linux Terminal",
        content: "I want you to act as a linux terminal. I will type commands and you will reply with what the terminal should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is pwd",
        tags: ["dev", "linux", "terminal"],
        category: "Development",
        isFavorite: true,
        isBuiltIn: true,
        builtInID: "awesome-linux-terminal"
      ),
      Prompt(
        shortID: "sys-lang-translator",
        title: "Act as an English Translator",
        content: "I want you to act as an English translator, spelling corrector and improver. I will speak to you in any language and you will detect the language, translate it and answer in the corrected and improved version of my text, in English. I want you to replace my simplified A0-level words and sentences with more beautiful and elegant, upper level English words and sentences. Keep the meaning same, but make them more literary. I want you to only reply the correction, the improvements and nothing else, do not write explanations.",
        tags: ["translation", "english", "writing"],
        category: "Language",
        isFavorite: true,
        isBuiltIn: true,
        builtInID: "awesome-english-translator"
      ),
      Prompt(
        shortID: "sys-hr-interviewer",
        title: "Act as an Interviewer",
        content: "I want you to act as an interviewer. I will be the candidate and you will ask me the interview questions for the position. I want you to only reply as the interviewer. Do not write all the conservation at once. I want you to only do the interview with me. Ask me the questions and wait for my answers. Do not write explanations. Ask me the questions one by one like an interviewer does and wait for my answers.",
        tags: ["career", "interview", "hr"],
        category: "Career",
        isBuiltIn: true,
        builtInID: "awesome-interviewer"
      ),
      Prompt(
        shortID: "sys-dev-jsconsole",
        title: "Act as a JavaScript Console",
        content: "I want you to act as a javascript console. I will type commands and you will reply with what the javascript console should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is console.log(\"Hello World\");",
        tags: ["dev", "js", "web"],
        category: "Development",
        isBuiltIn: true,
        builtInID: "awesome-javascript-console"
      ),
      Prompt(
        shortID: "sys-prod-excel",
        title: "Act as an Excel Sheet",
        content: "I want you to act as a text based excel. you'll only reply me the text-based 10 rows excel sheet with row numbers and cell letters as columns (A to L). First column header should be empty to reference row number. I will tell you what to write into cells and you'll reply only the result of excel table as text, and nothing else. Do not write explanations. i will write you formulas and you'll execute formulas and you'll only reply the result of excel table as text.",
        tags: ["data", "excel", "sheets"],
        category: "Productivity",
        isBuiltIn: true,
        builtInID: "awesome-excel-sheet"
      ),
      Prompt(
        shortID: "sys-ai-generator",
        title: "Act as a Prompt Generator",
        content: "I want you to act as a prompt generator. Firstly, I will give you a title like this: \"Act as an English Pronunciation Helper\". Then you give me a prompt like this: \"I want you to act as an English pronunciation assistant...\" (You should adapt the sample prompt according to the title I gave. The prompt should be self-explanatory and appropriate to the title).",
        tags: ["ai", "prompts", "meta"],
        category: "AI",
        isBuiltIn: true,
        builtInID: "awesome-prompt-generator"
      ),
      Prompt(
        shortID: "sys-design-ux",
        title: "Act as a UX/UI Developer",
        content: "I want you to act as a UX/UI developer. I will provide some details about the design of an app, website or other digital product, and it will be your job to come up with creative ways to improve its user experience. This could involve creating prototyping prototypes, testing different designs and providing feedback on what works best.",
        tags: ["design", "ux", "ui"],
        category: "Design",
        isBuiltIn: true,
        builtInID: "awesome-ux-ui-developer"
      ),
      Prompt(
        shortID: "sys-dev-sql",
        title: "Act as a SQL Terminal",
        content: "I want you to act as a SQL terminal in front of an example database. I will type queries and you will reply with what the terminal would show. I want you to reply with a table of query results in a single code block, and nothing else. Do not write explanations. Do not type commands unless I instruct you to do so.",
        tags: ["dev", "sql", "database"],
        category: "Development",
        isBuiltIn: true,
        builtInID: "awesome-sql-terminal"
      ),
      Prompt(
        shortID: "sys-write-plagiarism",
        title: "Act as a Plagiarism Checker",
        content: "I want you to act as a plagiarism checker. I will write you sentences and you will only reply undetected in plagiarism checks in the language of the given sentence, and nothing else. Do not write explanations on replies.",
        tags: ["writing", "academic", "qa"],
        category: "Writing",
        isBuiltIn: true,
        builtInID: "awesome-plagiarism-checker"
      ),
      Prompt(
        shortID: "sys-marketing-seo",
        title: "Act as an SEO Prompter",
        content: "I want you to act as an SEO expert. I will provide you with a target keyword and you will provide me with a list of 5 SEO-optimized blog post titles and meta descriptions. The titles should be catchy and click-inducing, and the meta descriptions should contain the target keyword.",
        tags: ["marketing", "seo", "blog"],
        category: "Marketing",
        isBuiltIn: true,
        builtInID: "awesome-seo-expert"
      ),
      Prompt(
        shortID: "sys-sec-cyber",
        title: "Act as a Cyber Security Specialist",
        content: "I want you to act as a cyber security specialist. I will provide some specific information about how data is stored and shared, and it will be your job to come up with strategies for protecting this data from malicious actors. This could include suggesting encryption methods, creating firewalls or implementing policies that track user activities.",
        tags: ["security", "cyber", "it"],
        category: "Security",
        isBuiltIn: true,
        builtInID: "awesome-cyber-security"
      ),
      Prompt(
        shortID: "sys-write-story",
        title: "Act as a Storyteller",
        content: "I want you to act as a storyteller. You will come up with entertaining stories that are engaging, imaginative and captivating for the audience. They can be fairy tales, educational stories or any other type of stories which has the potential to capture people's attention and imagination.",
        tags: ["writing", "creative", "fiction"],
        category: "Writing",
        isBuiltIn: true,
        builtInID: "awesome-storyteller"
      ),
      Prompt(
        shortID: "sys-prod-regex",
        title: "Act as a Regex Generator",
        content: "I want you to act as a regex generator. Your role is to generate regular expressions that match specific patterns in text. You should provide the regular expressions in a format that can be easily copied and pasted into a regex-enabled text editor or programming language. Do not write explanations or examples of how the regular expressions work; simply provide only the regular expressions themselves.",
        tags: ["dev", "regex", "productivity"],
        category: "Development",
        isBuiltIn: true,
        builtInID: "awesome-regex-generator"
      ),
      Prompt(
        shortID: "sys-dev-commit",
        title: "Act as a Commit Message Generator",
        content: "I want you to act as a commit message generator. I will provide you with information about the task and the prefix for the task code, and I would like you to generate an appropriate commit message using the conventional commit format. Do not write any explanations or other words, just reply with the commit message.",
        tags: ["dev", "git", "productivity"],
        category: "Development",
        isBuiltIn: true,
        builtInID: "awesome-commit-message"
      ),
      Prompt(
        shortID: "sys-write-poet",
        title: "Act as a Poet",
        content: "I want you to act as a poet. You will create poems that evoke emotions and have the power to stir people’s soul. Write on any topic or theme but make sure your words convey the feeling you are trying to express in beautiful yet meaningful ways. You can also come up with short verses that are still powerful enough to leave an imprint in readers' minds.",
        tags: ["writing", "creative", "poetry"],
        category: "Writing",
        isBuiltIn: true,
        builtInID: "awesome-poet"
      ),
      Prompt(
        shortID: "sys-life-coach",
        title: "Act as a Life Coach",
        content: "I want you to act as a life coach. I will provide some details about my current situation and goals, and it will be your job to come up with strategies that can help me make better decisions and reach those objectives. This could involve offering advice on various topics, such as creating plans for achieving success or dealing with difficult emotions.",
        tags: ["personal", "coach", "advice"],
        category: "Personal",
        isBuiltIn: true,
        builtInID: "awesome-life-coach"
      ),
      Prompt(
        shortID: "sys-prod-math",
        title: "Act as a Math Teacher",
        content: "I want you to act as a math teacher. I will provide some mathematical equations or concepts, and it will be your job to explain them in easy-to-understand terms. This could include providing step-by-step instructions for solving a problem, demonstrating various techniques with visuals or suggesting online resources for further study.",
        tags: ["education", "math", "learning"],
        category: "Education",
        isBuiltIn: true,
        builtInID: "awesome-math-teacher"
      ),
      Prompt(
        shortID: "sys-tech-reviewer",
        title: "Act as a Tech Reviewer",
        content: "I want you to act as a tech reviewer. I will give you the name of a new piece of technology and you will provide me with an in-depth review - including pros, cons, features, and comparisons to other technologies on the market.",
        tags: ["tech", "review", "analysis"],
        category: "Technology",
        isBuiltIn: true,
        builtInID: "awesome-tech-reviewer"
      ),
      Prompt(
        shortID: "sys-dev-reviewer",
        title: "Act as a Code Reviewer",
        content: "I want you to act as a code reviewer. I will provide you with a piece of code and you will review it for potential bugs, security vulnerabilities, and coding standard violations. You will provide a detailed report with suggestions for improvement.",
        tags: ["dev", "code", "review"],
        category: "Development",
        isBuiltIn: true,
        builtInID: "awesome-code-reviewer"
      ),
      Prompt(
        shortID: "sys-write-summary",
        title: "Act as a Summarizer",
        content: "I want you to act as a text summarizer. I will provide you with a text and you will summarize it in exactly one paragraph. Do not write any explanations or other words, just reply with the summary.",
        tags: ["productivity", "writing", "summary"],
        category: "Productivity",
        isBuiltIn: true,
        builtInID: "awesome-text-summarizer"
      )
    ]
  }
}

struct PromptWrapper: Codable {
  let version: String
  let prompts: [Prompt]
}
