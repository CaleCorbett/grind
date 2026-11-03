import Foundation
import EventKit

public struct ImportedTaskItem: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var notes: String?
    public var targetList: TaskListType
    public var reminderDate: Date?
    public var isEvening: Bool
    public var source: String
    public var checklistItems: [String]
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        notes: String? = nil,
        targetList: TaskListType = .next,
        reminderDate: Date? = nil,
        isEvening: Bool = false,
        source: String = "Apple Reminders",
        checklistItems: [String] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.targetList = targetList
        self.reminderDate = reminderDate
        self.isEvening = isEvening
        self.source = source
        self.checklistItems = checklistItems
    }
}

public final class RemindersImporterService {
    public static let shared = RemindersImporterService()
    
    private let eventStore = EKEventStore()
    
    public init() {}
    
    // MARK: - Apple Reminders Permissions & Fetch
    
    public func requestRemindersAccess() async -> Bool {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            // Non-bundled test runner: bypass system prompt
            return false
        }
        
        if #available(macOS 14.0, *) {
            do {
                return try await eventStore.requestFullAccessToReminders()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    public func fetchAppleReminders() async throws -> [ImportedTaskItem] {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return []
        }
        
        let granted = await requestRemindersAccess()
        guard granted else {
            throw NSError(domain: "Slate.RemindersImporter", code: 403, userInfo: [NSLocalizedDescriptionKey: "Reminders access was not granted."])
        }
        
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { ekReminders in
                guard let ekReminders = ekReminders else {
                    continuation.resume(returning: [])
                    return
                }
                
                let calendar = Calendar.current
                let todayStart = calendar.startOfDay(for: Date())
                
                var items: [ImportedTaskItem] = []
                for reminder in ekReminders {
                    let title = (reminder.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { continue }
                    
                    var targetList: TaskListType = .next
                    var reminderDate: Date? = nil
                    var isEvening = false
                    
                    if let components = reminder.dueDateComponents, let date = calendar.date(from: components) {
                        reminderDate = date
                        if calendar.isDateInToday(date) || date < todayStart {
                            targetList = .today
                            if let hour = components.hour, hour >= 18 {
                                isEvening = true
                            }
                        } else {
                            targetList = .next
                        }
                    }
                    
                    let item = ImportedTaskItem(
                        id: reminder.calendarItemIdentifier,
                        title: title,
                        notes: reminder.notes,
                        targetList: targetList,
                        reminderDate: reminderDate,
                        isEvening: isEvening,
                        source: reminder.calendar?.title ?? "Apple Reminders"
                    )
                    items.append(item)
                }
                continuation.resume(returning: items)
            }
        }
    }
    
    // MARK: - Things 3 & Generic JSON Parser
    
    public func parseThingsJSON(_ data: Data) throws -> [ImportedTaskItem] {
        // First check for JSON object/array
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        
        var results: [ImportedTaskItem] = []
        let calendar = Calendar.current
        
        // Helper to parse individual dictionary
        func parseDict(_ dict: [String: Any]) {
            // Things 3 schema: {"type": "to-do", "attributes": {...}}
            let attributes = dict["attributes"] as? [String: Any] ?? dict
            
            guard let title = (attributes["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else { return }
            
            let notes = attributes["notes"] as? String
            let when = (attributes["when"] as? String)?.lowercased() ?? ""
            let listStr = (attributes["list"] as? String)?.lowercased() ?? ""
            
            var targetList: TaskListType = .next
            var isEvening = false
            var reminderDate: Date? = nil
            
            if when == "today" || listStr == "today" {
                targetList = .today
            } else if when == "someday" || listStr == "someday" {
                targetList = .someday
            } else if when == "evening" || attributes["isEvening"] as? Bool == true {
                targetList = .today
                isEvening = true
            } else if let deadlineStr = attributes["deadline"] as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
                if let d = formatter.date(from: deadlineStr) {
                    reminderDate = d
                    if calendar.isDateInToday(d) || d < calendar.startOfDay(for: Date()) {
                        targetList = .today
                    } else {
                        targetList = .next
                    }
                }
            }
            
            // Check for checklist items
            var checklist: [String] = []
            if let items = attributes["checklist-items"] as? [[String: Any]] {
                for item in items {
                    let itemAttrs = item["attributes"] as? [String: Any] ?? item
                    if let itemTitle = itemAttrs["title"] as? String, !itemTitle.isEmpty {
                        checklist.append(itemTitle)
                    }
                }
            } else if let items = attributes["checklist"] as? [String] {
                checklist = items
            }
            
            let item = ImportedTaskItem(
                title: title,
                notes: notes,
                targetList: targetList,
                reminderDate: reminderDate,
                isEvening: isEvening,
                source: "Things 3 / JSON",
                checklistItems: checklist
            )
            results.append(item)
        }
        
        if let array = jsonObject as? [[String: Any]] {
            for dict in array {
                parseDict(dict)
            }
        } else if let dict = jsonObject as? [String: Any] {
            if let items = dict["items"] as? [[String: Any]] {
                for d in items { parseDict(d) }
            } else {
                parseDict(dict)
            }
        }
        
        return results
    }
    
    // MARK: - Plain Text / Markdown Importer
    
    public func parsePlainTextTasks(_ text: String, defaultList: TaskListType = .next) -> [ImportedTaskItem] {
        let lines = text.components(separatedBy: .newlines)
        var results: [ImportedTaskItem] = []
        
        for rawLine in lines {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            
            // Strip markdown checkboxes: "- [ ] ", "- [x] ", "* ", "- "
            if line.hasPrefix("- [ ] ") || line.hasPrefix("- [x] ") {
                line = String(line.dropFirst(6))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                line = String(line.dropFirst(2))
            } else if line.hasPrefix("[ ] ") {
                line = String(line.dropFirst(4))
            }
            line = line.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            
            // Pass through QuickAddParser for automatic list/date detection
            let parsed = QuickAddParser.parse(line)
            let targetList = parsed.targetList
            
            let item = ImportedTaskItem(
                title: parsed.cleanTitle.isEmpty ? line : parsed.cleanTitle,
                targetList: targetList,
                reminderDate: parsed.reminderDate,
                isEvening: parsed.isEvening,
                source: "Plain Text"
            )
            results.append(item)
        }
        
        return results
    }
    
    // MARK: - DataStore Import Execution
    
    @MainActor
    public func importItems(_ items: [ImportedTaskItem], store: DataStore? = nil, skipDuplicates: Bool = true) -> Int {
        let targetStore = store ?? DataStore.shared
        var existingTitles = Set<String>()
        if skipDuplicates {
            let allTasks = targetStore.todayTasks + targetStore.nextTasks + targetStore.somedayTasks + targetStore.archivedTasks
            for task in allTasks {
                existingTitles.insert(task.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            }
        }
        
        var importedCount = 0
        for item in items {
            let titleNormalized = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if skipDuplicates && existingTitles.contains(titleNormalized) {
                continue
            }
            
            var checklistJSON: String? = nil
            if !item.checklistItems.isEmpty {
                if let data = try? JSONSerialization.data(withJSONObject: item.checklistItems, options: []),
                   let str = String(data: data, encoding: .utf8) {
                    checklistJSON = str
                }
            }
            
            targetStore.addTask(
                title: item.title,
                to: item.targetList,
                notes: item.notes,
                reminderDate: item.reminderDate,
                isEvening: item.isEvening,
                checklistJSON: checklistJSON
            )
            existingTitles.insert(titleNormalized)
            importedCount += 1
        }
        
        return importedCount
    }
}
