import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
public final class DataStore: ObservableObject {
    public static let shared = DataStore()
    
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }
    
    @Published public private(set) var todayTasks: [TodoTask] = []
    @Published public private(set) var nextTasks: [TodoTask] = []
    @Published public private(set) var somedayTasks: [TodoTask] = []
    @Published public private(set) var archivedTasks: [TodoTask] = []
    @Published public private(set) var todayRemainingCount: Int = 0
    @Published public private(set) var todayTotalCount: Int = 0
    
    @Published public var refreshTrigger: UUID = UUID() {
        didSet {
            reloadAll()
        }
    }
    
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
        reloadAll()
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
    
    public func reloadAll() {
        let moveCompleted = UserDefaults.standard.object(forKey: "moveCompletedToBottom") as? Bool ?? true
        
        let fetchedToday = fetchTasksFromStore(for: .today, moveCompletedToBottom: moveCompleted)
        let fetchedNext = fetchTasksFromStore(for: .next, moveCompletedToBottom: moveCompleted)
        let fetchedSomeday = fetchTasksFromStore(for: .someday, moveCompletedToBottom: moveCompleted)
        
        self.todayTasks = fetchedToday
        self.nextTasks = fetchedNext
        self.somedayTasks = fetchedSomeday
        self.todayTotalCount = fetchedToday.count
        self.todayRemainingCount = fetchedToday.filter { $0.status != .completed }.count
        
        let archiveDesc = FetchDescriptor<TodoTask>(
            predicate: #Predicate<TodoTask> { task in
                task.isArchived || task.rawStatus == 2
            },
            sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
        )
        self.archivedTasks = (try? context.fetch(archiveDesc)) ?? []
    }
    
    private func fetchTasksFromStore(for list: TaskListType, moveCompletedToBottom: Bool) -> [TodoTask] {
        let raw = list.rawValue
        let predicate = #Predicate<TodoTask> { task in
            task.rawList == raw && !task.isArchived
        }
        var descriptor = FetchDescriptor<TodoTask>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.orderIndex, order: .forward)]
        
        var listTasks = (try? context.fetch(descriptor)) ?? []
        
        if moveCompletedToBottom {
            listTasks.sort { a, b in
                if (a.status == .completed) == (b.status == .completed) {
                    return a.orderIndex < b.orderIndex
                }
                return a.status != .completed
            }
        }
        return listTasks
    }
    
    public func tasks(for list: TaskListType, includeArchived: Bool = false) -> [TodoTask] {
        if !includeArchived {
            switch list {
            case .today: return todayTasks
            case .next: return nextTasks
            case .someday: return somedayTasks
            }
        }
        let raw = list.rawValue
        let predicate = #Predicate<TodoTask> { task in
            task.rawList == raw
        }
        var descriptor = FetchDescriptor<TodoTask>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.orderIndex, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }
    
    public func task(with id: UUID) -> TodoTask? {
        if let found = (todayTasks + nextTasks + somedayTasks).first(where: { $0.id == id }) {
            return found
        }
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
        reloadAll()
    }
    
    public func toggleTaskStatus(_ task: TodoTask) {
        let prev = task.status
        let next = prev.nextStatus(allowInProgress: AppSettings.shared.allowInProgress)
        task.status = next
        if next == .completed && AppSettings.shared.archiveImmediately {
            task.isArchived = true
        }
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
        
        reloadAll()
    }
    
    public func moveTask(_ task: TodoTask, to list: TaskListType) {
        guard task.list != list else { return }
        let existing = tasks(for: list)
        let order = (AppSettings.shared.addTaskPosition == "top")
            ? (existing.map(\.orderIndex).min() ?? 0) - 1
            : (existing.map(\.orderIndex).max() ?? 0) + 1
        task.list = list
        task.orderIndex = order
        try? context.save()
        SoundManager.shared.play(.button)
        reloadAll()
    }
    
    /// Reorders `draggedTask` directly before `targetTask` (moving across lists if needed).
    public func reorderTask(_ draggedTask: TodoTask, before targetTask: TodoTask) {
        guard draggedTask.id != targetTask.id else { return }
        let destinationList = targetTask.list
        draggedTask.list = destinationList
        
        var listItems = tasks(for: destinationList).filter { $0.id != draggedTask.id }
        if let targetIdx = listItems.firstIndex(where: { $0.id == targetTask.id }) {
            listItems.insert(draggedTask, at: targetIdx)
        } else {
            listItems.append(draggedTask)
        }
        
        for (idx, item) in listItems.enumerated() {
            item.orderIndex = idx
        }
        
        try? context.save()
        SoundManager.shared.play(.button)
        reloadAll()
    }
    
    public func deleteTask(_ task: TodoTask) {
        ReminderService.shared.cancelReminder(for: task)
        UndoToastManager.shared.recordDeletion(of: task)
        context.delete(task)
        try? context.save()
        SoundManager.shared.play(.deleted)
        reloadAll()
    }
    
    public func deleteTasks(_ tasksToDelete: [TodoTask]) {
        guard !tasksToDelete.isEmpty else { return }
        for task in tasksToDelete {
            ReminderService.shared.cancelReminder(for: task)
        }
        UndoToastManager.shared.recordDeletion(of: tasksToDelete)
        for task in tasksToDelete {
            context.delete(task)
        }
        try? context.save()
        SoundManager.shared.play(tasksToDelete.count > 1 ? .allDeleted : .deleted)
        reloadAll()
    }
    
    public func moveTasks(_ tasksToMove: [TodoTask], to list: TaskListType) {
        let valid = tasksToMove.filter { $0.list != list }
        guard !valid.isEmpty else { return }
        let existing = tasks(for: list)
        var nextOrder = (AppSettings.shared.addTaskPosition == "top")
            ? (existing.map(\.orderIndex).min() ?? 0) - valid.count
            : (existing.map(\.orderIndex).max() ?? 0) + 1
        
        for task in valid {
            task.list = list
            task.orderIndex = nextOrder
            nextOrder += 1
        }
        try? context.save()
        SoundManager.shared.play(.button)
        reloadAll()
    }
    
    public func setStatus(_ status: TaskStatus, for targetTasks: [TodoTask]) {
        guard !targetTasks.isEmpty else { return }
        for task in targetTasks {
            task.status = status
            if status == .completed {
                ReminderService.shared.cancelReminder(for: task)
                if AppSettings.shared.archiveImmediately {
                    task.isArchived = true
                }
            } else if status == .incomplete, task.reminderDate != nil {
                ReminderService.shared.scheduleReminder(for: task)
            }
        }
        try? context.save()
        switch status {
        case .completed:
            SoundManager.shared.play(.completed)
        case .inProgress:
            SoundManager.shared.play(.inProgress)
        case .incomplete:
            SoundManager.shared.play(.button)
        }
        reloadAll()
    }
    
    public func clearCompleted(in list: TaskListType) {
        let completed = tasks(for: list).filter { $0.status == .completed }
        guard !completed.isEmpty else { return }
        for t in completed {
            t.isArchived = true
        }
        try? context.save()
        SoundManager.shared.play(.allDeleted)
        reloadAll()
    }
}
