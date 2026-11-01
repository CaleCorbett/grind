import Foundation
import AppIntents

public struct AddTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add Task to Grind"
    public static var description = IntentDescription("Creates a new to-do in Grind.")
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "List", default: "today")
    public var listName: String
    
    @Parameter(title: "Notes")
    public var notes: String?
    
    @Parameter(title: "Is Evening", default: false)
    public var isEvening: Bool
    
    public init() {}
    
    public init(title: String, listName: String = "today", notes: String? = nil, isEvening: Bool = false) {
        self.title = title
        self.listName = listName
        self.notes = notes
        self.isEvening = isEvening
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let targetList = TaskListType(rawValue: listName.lowercased()) ?? .today
        DataStore.shared.addTask(
            title: title,
            to: targetList,
            notes: notes,
            isEvening: isEvening
        )
        return .result(dialog: "Added “\(title)” to \(targetList.title).")
    }
}

public struct GetTodayTasksIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Today Tasks from Grind"
    public static var description = IntentDescription("Returns the list of active to-dos for Today.")
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let titles = DataStore.shared.todayTasks.filter { $0.status != .completed }.map(\.title)
        let count = titles.count
        let dialog: IntentDialog = count == 0
            ? "You have no remaining tasks in Today."
            : "You have \(count) task\(count == 1 ? "" : "s") in Today: \(titles.joined(separator: ", "))."
        return .result(value: titles, dialog: dialog)
    }
}

public struct ToggleTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Complete Grind Task"
    public static var description = IntentDescription("Marks the first matching task as complete.")
    
    @Parameter(title: "Task Title")
    public var taskTitle: String
    
    public init() {}
    
    public init(taskTitle: String) {
        self.taskTitle = taskTitle
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let all = DataStore.shared.todayTasks + DataStore.shared.nextTasks + DataStore.shared.somedayTasks
        if let match = all.first(where: { $0.title.localizedCaseInsensitiveContains(taskTitle) }) {
            DataStore.shared.toggleTaskStatus(match)
            return .result(dialog: "Updated “\(match.title)” to \(match.status.rawValue == 2 ? "Done" : "In Progress").")
        } else {
            return .result(dialog: "No task matching “\(taskTitle)” found in Grind.")
        }
    }
}

public struct GrindShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add to \(.applicationName)",
                "Create \(.applicationName) to-do"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: GetTodayTasksIntent(),
            phrases: [
                "What's on my \(.applicationName) today",
                "Show \(.applicationName) Today tasks"
            ],
            shortTitle: "Today Tasks",
            systemImageName: "sun.max"
        )
    }
}

