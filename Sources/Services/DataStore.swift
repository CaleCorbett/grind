import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
public final class DataStore: ObservableObject {
    public static let shared = DataStore()
    
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }
    
    @Published public var refreshTrigger: UUID = UUID()
    
    private init() {
        let schema = Schema([TodoTask.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let persistentContainer = try? ModelContainer(for: schema, configurations: [config]) {
            self.container = persistentContainer
        } else {
            // Fallback to in-memory store if on-disk schema cannot be migrated or opened
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            self.container = (try? ModelContainer(for: schema, configurations: [memConfig])) ?? {
                fatalError("Fatal: Failed to initialize even an in-memory ModelContainer")
            }()
        }
        seedStarterTasksIfNeeded()
    }
    
    public func seedStarterTasksIfNeeded() {
        let descriptor = FetchDescriptor<TodoTask>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        
        let starterTasks: [(String, TaskListType, TaskStatus, String?, Date?)] = [
            // Today
            ("Review Q2 proposal", .today, .inProgress, nil, nil),
            ("Call dentist", .today, .incomplete, nil, nil),
            ("Send invoice to Acme Co.", .today, .incomplete, nil, Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())),
            ("Pick up groceries", .today, .incomplete, "Milk, sourdough bread, organic eggs, avocados, cold brew.", nil),
            ("Standup at 9", .today, .completed, nil, nil),
            ("Morning run", .today, .completed, nil, nil),
            
            // Next
            ("Finalize pitch deck", .next, .incomplete, "Send link to investors before Friday review call.", nil),
            ("Plan Barcelona trip", .next, .incomplete, nil, nil),
            ("Annual checkup", .next, .incomplete, nil, nil),
            ("Reply to Sarah", .next, .incomplete, nil, nil),
            
            // Someday
            ("Run a half marathon", .someday, .incomplete, nil, nil),
            ("Read “Atomic Habits”", .someday, .incomplete, "By James Clear. Recommended by Tim.", nil),
            ("Visit Japan in spring", .someday, .incomplete, "Cherry blossom season in Kyoto & Tokyo.", nil),
            ("Start a podcast", .someday, .incomplete, nil, nil)
        ]
        
        for (i, item) in starterTasks.enumerated() {
            let task = TodoTask(
                title: item.0,
                list: item.1,
                status: item.2,
                notes: item.3,
                reminderDate: item.4,
                orderIndex: i
            )
            context.insert(task)
        }
        try? context.save()
    }
    
    public func tasks(for list: TaskListType, includeArchived: Bool = false) -> [TodoTask] {
        let raw = list.rawValue
        let predicate = #Predicate<TodoTask> { task in
            task.rawList == raw && (includeArchived || !task.isArchived)
        }
        var descriptor = FetchDescriptor<TodoTask>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.orderIndex, order: .forward)]
        
        var listTasks = (try? context.fetch(descriptor)) ?? []
        
        if AppSettings.shared.moveCompletedToBottom {
            listTasks.sort { a, b in
                if (a.status == .completed) == (b.status == .completed) {
                    return a.orderIndex < b.orderIndex
                }
                return a.status != .completed
            }
        }
        return listTasks
    }
    
    public func task(with id: UUID) -> TodoTask? {
        let descriptor = FetchDescriptor<TodoTask>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
    
    public func addTask(title: String, to list: TaskListType, notes: String? = nil, reminderDate: Date? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let existing = tasks(for: list)
        let order = (AppSettings.shared.addTaskPosition == "top")
            ? (existing.map(\.orderIndex).min() ?? 0) - 1
            : (existing.map(\.orderIndex).max() ?? 0) + 1
        
        let task = TodoTask(
            title: trimmed,
            list: list,
            status: .incomplete,
            notes: notes,
            reminderDate: reminderDate,
            orderIndex: order
        )
        context.insert(task)
        try? context.save()
        
        if task.reminderDate != nil {
            ReminderService.shared.scheduleReminder(for: task)
        }
        
        SoundManager.shared.play(.button)
        refreshTrigger = UUID()
    }
    
    public func toggleTaskStatus(_ task: TodoTask) {
        let prev = task.status
        let next = prev.nextStatus(allowInProgress: AppSettings.shared.allowInProgress)
        task.status = next
        try? context.save()
        
        switch next {
        case .completed:
            ReminderService.shared.cancelReminder(for: task)
            SoundManager.shared.play(.completed)
        case .inProgress:
            SoundManager.shared.play(.inProgress)
        case .incomplete:
            if task.reminderDate != nil {
                ReminderService.shared.scheduleReminder(for: task)
            }
            SoundManager.shared.play(.button)
        }
        
        refreshTrigger = UUID()
    }
    
    public func moveTask(_ task: TodoTask, to list: TaskListType) {
        guard task.list != list else { return }
        task.list = list
        try? context.save()
        SoundManager.shared.play(.button)
        refreshTrigger = UUID()
    }
    
    public func deleteTask(_ task: TodoTask) {
        ReminderService.shared.cancelReminder(for: task)
        UndoToastManager.shared.recordDeletion(of: task)
        context.delete(task)
        try? context.save()
        SoundManager.shared.play(.deleted)
        refreshTrigger = UUID()
    }
    
    public func clearCompleted(in list: TaskListType) {
        let completed = tasks(for: list).filter { $0.status == .completed }
        guard !completed.isEmpty else { return }
        for t in completed {
            t.isArchived = true
        }
        try? context.save()
        SoundManager.shared.play(.allDeleted)
        refreshTrigger = UUID()
    }
}
