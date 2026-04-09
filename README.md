# PromptNow

**PromptNow** is a lightning-fast, keyboard-first macOS menu bar utility designed for AI power users and content creators. It gives you instant access to your favorite AI prompts from anywhere on your Mac. Simply hit `Option + Space` to bring up a Spotlight-like search window, instantly find your prompt, and hit `Enter` to copy it straight to your clipboard.

*PromptNow is open-source, beautifully native, and highly optimized for macOS Sonoma and later.*

---

## 🌟 Acknowledgements

**PromptNow** is heavily inspired by and built upon the excellent foundation of [Maccy](https://github.com/p0deje/Maccy), the beloved lightweight clipboard manager for macOS created by Alexey Rodionov (@p0deje). 

We have carefully refactored Maccy's proven UI architecture to pivot from a dynamic clipboard manager to a hyper-focused static prompt library. We stripped out the continuous clipboard monitoring, auto-pasting mechanisms, and accessibility requirements to create a streamlined, privacy-first tool explicitly meant for AI workflows.

## 🚀 Features

- **Keyboard-First Workflow:** Activated via a single global hotkey (`Option + Space` by default). Navigate entirely without your mouse.
- **Fuzzy Search:** Instantly locate your prompts by searching across titles, content, and metadata tags in real time.
- **Glassmorphic UI:** A premium, native macOS interface built with SwiftUI, featuring `ultraThinMaterial` backgrounds.
- **Zero Friction:** No Accessibility Permissions required! PromptNow operates cleanly via standard clipboard copy mechanisms.
- **Privacy First:** 100% offline. Your prompt library (`prompts.json`) is stored locally and securely on your machine.
- **SwiftData Persistence:** Robust, modern local data storage architecture ensuring instantaneous loading.

## 🛠 Required Setup

The application automatically seeds a default library of high-quality AI prompts (Development, Marketing, QA, etc.) upon first launch to help you get started.

### Building from Source

1. Clone the repository.
2. Open `PromptNow.xcodeproj` in Xcode (requires macOS 14 Sonoma+ and Xcode 15+).
3. Build and Run.

### Managing Prompts

Because PromptNow is an MVP, the primary way to batch-add your custom prompts is via the `prompts.json` file located at:
`~/Library/Application Support/PromptNow/prompts.json`

You can manually edit this file in your favorite text editor to add your own prompts. The app syncs with this JSON file on database initialization. 

*(A fully-featured UI Editor for adding and mutating prompts directly within the app is coming in Phase 2!)*

## 💡 Usage

1. Press `Option + Space`.
2. Type a few characters to fuzzy-search your prompt list.
3. Use `Up`/`Down` arrow keys to navigate the list, previewing the full prompt text in the bottom pane.
4. Press `Enter` to copy the selected prompt. A minimalist "Copied!" toast will appear.
5. Paste (`Cmd + V`) your prompt straight into ChatGPT, Claude, Cursor, or any text editor.

## 📝 License

PromptNow is released under the [MIT License](LICENSE), reflecting the original license of the Maccy project.
