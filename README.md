# Slate — Clean slate. Quiet focus.

A 100% native macOS to-do application built on a strict, minimalist three-list system: **Today**, **Next**, and **Someday**. Zero clutter, zero endless organization traps—know what to do today and execute.

---

## 🌟 Highlights & Features

- **The Three-List Framework**:
  - **Today**: Short, ruthless daily focus list (`#FFFFFF` in light mode, `#1A1A1A` in dark mode).
  - **Next**: Upcoming priorities without cluttering Today (`#FBF8EF` in light mode, `#151515` in dark mode).
  - **Someday**: Ideas, long-term aspirations, and maybe-laters (`#FDF5E6` in light mode, `#111111` in dark mode).
- **The Signature 3-State Checkbox Cycle**:
  - Click 1: **To Do** → **In Progress** (180° animated conic pie sweep with `TaskInProgress` sound).
  - Click 2: **In Progress** → **Done** (smooth checkmark pop + title strikethrough wipe with `TaskCompleted` sound).
  - Click 3: **Done** → **To Do** (resets status).
  - Configurable to 2-step (To Do ↔ Done) in Settings.
- **Smart Quick-Add with Natural Language Parsing**:
  - Global capture: Press `^⌥Space` (Control + Option + Space) from anywhere in macOS.
  - Type e.g. `dentist Friday 3pm` → automatically sets reminder for Friday 3:00 PM and selects the right card.
  - Real-time pill chips for list selection and date confirmation.
- **macOS Services & Deep Links**:
  - Highlight text anywhere on macOS → Right Click → Services → **Send to Slate**.
  - Deep link support: `slate://add?title=Deep%20Work&list=today`.
- **Keyboard-First Navigation**:
  - Vim/arrow keys (`↑`/`↓`/`←`/`→`, `J`/`K`/`H`/`L`) to navigate between cards and tasks.
  - `Space` to cycle status, `Return` to inline expand, `⌘T`/`⌘E`/`⌘S` to move, `⌫` to delete.
- **Safety Net & Recently Deleted (Trash)**:
  - Soft deletion with instant `⌘Z` undo toast.
  - Dedicated trash bin with individual task restore and "Empty Trash" purge.
- **Backup & Standup Export**:
  - Export all to-dos as clean Markdown outline (`.md`) or full JSON backup (`.json`).
  - Copy Today's formatted standup summary to clipboard (`⌘⇧C`).
- **Focus Timer & Fresh Start Ritual**:
  - 25-minute quiet focus timer with menu bar countdown and automatic progress logging.
  - Morning fresh start prompt to review yesterday's unfinished tasks without guilt.
- **Custom Tactile Sound Effects**:
  - Synthesized audio feedback for task completion, in-progress sweep, deletion, and quick-add chimes.
- **Geist Typography & Custom Styling**:
  - Bundled with Vercel Geist fonts (`Geist-Regular`, `Medium`, `SemiBold`, `Bold`, `Mono`).
  - Authentic macOS Big Sur architectural squircle icon with tactile dark graphite and signal-amber accent.
- **Offline-First SwiftData Persistence**:
  - 100% local SQLite storage, zero telemetry, zero accounts, and 0.0% idle CPU.

---

## 🚀 Running the App

### 1. Build and Install
Run the build script from the repository root:
```bash
./build_app.sh
```
This compiles the application, embeds all assets, and installs directly to `/Applications/Slate.app`.

### 2. Launch the Application
```bash
open /Applications/Slate.app
```

### 3. Open in Xcode
Generate the project file and open in Xcode:
```bash
xcodegen generate
open Slate.xcodeproj
```

---

## ⌨️ Shortcuts

| Shortcut | Action |
|---|---|
| `^⌥Space` | Global Quick-Add HUD (from any app in macOS) |
| `⌘N` | Open Quick-Add HUD inside Slate |
| `⌘Z` | Undo last delete |
| `⌘⇧C` | Copy Today's tasks as Standup Summary |
| `↑` / `↓` / `J` / `K` | Move selection up and down |
| `←` / `→` / `H` / `L` | Switch between Today, Next, and Someday |
| `Space` | Cycle task status (Incomplete → In Progress → Done) |
| `⌘T` / `⌘E` / `⌘S` | Move selected task to Today, Next, or Someday |
| `⌫` (Delete) | Move selected task to Trash |
| `⌘,` | Open Settings |
| `Escape` | Dismiss modal / Quick-Add HUD |

---

## 📄 License & Attribution

- **Code**: Licensed under the [MIT License](LICENSE).
- **Typography**: [Geist Font Family](https://vercel.com/font) by Vercel Inc., licensed under the [SIL Open Font License 1.1](Resources/Geist-OFL.txt).
- **Audio & Assets**: All audio effects, app icons, and graphics are original creations or native Apple SF Symbols.
