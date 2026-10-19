# Grind — Focus. Check. Repeat.

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
- **Custom Tactile Sound Effects**:
  - Original synthesized audio feedback for task completion, in-progress sweep, deletion, and quick-add chimes.
- **Geist Typography & Custom Styling**:
  - Bundled with Vercel Geist fonts:
    - `Geist-Regular.otf`, `Geist-Medium.otf`, `Geist-SemiBold.otf`, `Geist-Bold.otf`
    - `GeistMono-*` and `GeistPixel-Square.otf`
  - Exact card corner radiuses, resting and floating shadow stacks, and dynamic light/dark colors.
- **macOS Menu Bar Extra**:
  - Menu bar icon with badge counter for Today's tasks.
  - Dropdown popover allowing you to check off Today's tasks and add new items without opening the main window.
- **Task Detail Sheet**:
  - Multiline notes editor with link detection.
  - Reminder picker with date & time.
  - Card selector and status controls.
- **Auto-Move & Archive System**:
  - Daily sweep rolling over today's reminders to the Today card.
  - Search and browse completed tasks with one-click restore.
  - Floating Delete Undo toast with `⌘Z` support.
- **Offline-First Persistence**:
  - Built on SwiftData with automatic persistence and zero telemetry.

---

## 🚀 Running the App

### 1. Build and Package `.app`
Run the build script from the repository root:
```bash
./build_app.sh
```
This compiles all Swift sources with `swiftc`, embeds all fonts, sounds, and assets into `build/Grind.app`, and signs the bundle.

### 2. Launch the Application
```bash
open build/Grind.app
```

### 3. Open in Xcode
Open the directory in Xcode to develop or debug:
```bash
open -a Xcode .
```

---

## ⌨️ Shortcuts

| Shortcut | Action |
|---|---|
| `^⌥Space` | Global Quick-Add HUD (Any app in macOS) |
| `⌘N` | Open Quick-Add HUD inside Grind |
| `⌘Z` | Undo last delete |
| `⌘,` | Open Settings |
| `Return` | Save task in inline entry or Quick-Add |
| `Escape` | Dismiss modal / Quick-Add HUD |

---

## 📄 License & Attribution

- **Code**: Licensed under the [MIT License](LICENSE).
- **Typography**: [Geist Font Family](https://vercel.com/font) by Vercel Inc., licensed under the [SIL Open Font License 1.1](Resources/Geist-OFL.txt).
- **Audio & Assets**: All audio effects, app icons, and graphics are original creations or native Apple SF Symbols.
- **Disclaimer**: *Grind is an independent, open-source productivity app created for focused task management. It is not affiliated with, sponsored by, or endorsed by Studio 257 or Hustla.*
