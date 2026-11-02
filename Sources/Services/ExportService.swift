import Foundation
import AppKit

@MainActor
public final class ExportService {
    public static let shared = ExportService()
    
    private init() {}
    
    // MARK: - Markdown Outline Generation
    
    public func generateMarkdownOutline(includeArchived: Bool = true) -> String {
        let store = DataStore.shared
        let dateStr = AppSettings.streakDateFormatter.string(from: Date())
        var lines: [String] = [
            "# Grind To-Do Outline",
            "Exported: \(dateStr)",
            ""
        ]
        
        func appendList(_ title: String, tasks: [TodoTask]) {
            lines.append("## \(title) (\(tasks.count))")
            if tasks.isEmpty {
                lines.append("_No to-dos_")
            } else {
                for t in tasks {
                    let box = t.status == .completed ? "[x]" : (t.status == .inProgress ? "[/]" : "[ ]")
                    var line = "- \(box) \(t.title)"
                    if t.isEvening { line += " 🌙" }
                    if let rule = t.recurrenceRule { line += " ↻ \(rule)" }
                    if t.focusSecondsLogged > 0 {
                        line += " (\(t.focusSecondsLogged / 60)m focus)"
                    }
                    lines.append(line)
                    if let notes = t.notes, !notes.isEmpty {
                        for n in notes.components(separatedBy: .newlines) {
                            lines.append("  > \(n)")
                        }
                    }
                    for item in t.checklist {
                        let cbox = item.isCompleted ? "[x]" : "[ ]"
                        lines.append("  - \(cbox) \(item.title)")
                    }
                }
            }
            lines.append("")
        }
        
        appendList("Today", tasks: store.todayTasks)
        appendList("Next", tasks: store.nextTasks)
        appendList("Someday", tasks: store.somedayTasks)
        if includeArchived {
            appendList("Logbook / Archive", tasks: store.archivedTasks)
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - JSON Backup Generation
    
    public func generateJSONBackup() -> Data? {
        let store = DataStore.shared
        let allTasks = store.todayTasks + store.nextTasks + store.somedayTasks + store.archivedTasks
        let payload: [[String: Any]] = allTasks.map { t in
            var dict: [String: Any] = [
                "id": t.id.uuidString,
                "title": t.title,
                "list": t.list.rawValue,
                "status": t.status.rawValue,
                "isEvening": t.isEvening,
                "isArchived": t.isArchived,
                "creationDate": ISO8601DateFormatter().string(from: t.creationDate),
                "focusSecondsLogged": t.focusSecondsLogged
            ]
            if let n = t.notes { dict["notes"] = n }
            if let r = t.reminderDate { dict["reminderDate"] = ISO8601DateFormatter().string(from: r) }
            if let rec = t.recurrenceRule { dict["recurrenceRule"] = rec }
            let checklist = t.checklist
            if !checklist.isEmpty {
                dict["checklist"] = checklist.map { ["title": $0.title, "isCompleted": $0.isCompleted] }
            }
            return dict
        }
        
        return try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }
    
    // MARK: - Today Standup Summary Generation
    
    public func generateTodayStandupSummary() -> String {
        let store = DataStore.shared
        let today = store.todayTasks
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        var lines: [String] = ["**Today's Update (\(dateStr))**"]
        
        let completed = today.filter { $0.status == .completed }
        let inProgress = today.filter { $0.status == .inProgress }
        let planned = today.filter { $0.status == .incomplete }
        
        if !completed.isEmpty {
            lines.append("\n*Completed:*")
            for t in completed {
                var item = "- [x] \(t.title)"
                if t.focusSecondsLogged > 0 {
                    let mins = t.focusSecondsLogged / 60
                    item += " (\(mins)m focus)"
                }
                lines.append(item)
            }
        }
        
        if !inProgress.isEmpty {
            lines.append("\n*In Progress:*")
            for t in inProgress {
                var item = "- [/] \(t.title)"
                if t.focusSecondsLogged > 0 {
                    let mins = t.focusSecondsLogged / 60
                    item += " (\(mins)m focus)"
                }
                lines.append(item)
            }
        }
        
        if !planned.isEmpty {
            lines.append("\n*Next Up / Planned:*")
            for t in planned {
                lines.append("- [ ] \(t.title)")
            }
        }
        
        if today.isEmpty {
            lines.append("\n_No to-dos scheduled for Today._")
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Clipboard & Save Panels
    
    public func copyTodayStandupSummaryToClipboard() {
        let summary = generateTodayStandupSummary()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(summary, forType: .string)
        UndoToastManager.shared.showInfo("Copied Today's summary to clipboard")
    }
    
    public func exportMarkdownToFile() {
        let md = generateMarkdownOutline()
        guard let data = md.data(using: .utf8) else { return }
        let dateStr = AppSettings.streakDateFormatter.string(from: Date())
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "grind-tasks-\(dateStr).md"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
            UndoToastManager.shared.showInfo("Exported Markdown outline to \(url.lastPathComponent)")
        }
    }
    
    public func exportJSONToFile() {
        guard let data = generateJSONBackup() else { return }
        let dateStr = AppSettings.streakDateFormatter.string(from: Date())
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "grind-backup-\(dateStr).json"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
            UndoToastManager.shared.showInfo("Exported JSON backup to \(url.lastPathComponent)")
        }
    }
}
