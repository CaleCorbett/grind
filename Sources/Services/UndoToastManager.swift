import SwiftUI
import Combine

public struct DeletedTaskSnapshot {
    public let id: UUID
    public let title: String
    public let list: TaskListType
    public let status: TaskStatus
    public let notes: String?
    public let reminderDate: Date?
    public let orderIndex: Int
}

@MainActor
public final class UndoToastManager: ObservableObject {
    public static let shared = UndoToastManager()
    
    @Published public var currentToastMessage: String? = nil
    @Published public var canUndo: Bool = false
    
    private var lastDeleted: DeletedTaskSnapshot? = nil
    private var dismissTimer: Timer?
    
    private init() {}
    
    public func recordDeletion(of task: TodoTask) {
        lastDeleted = DeletedTaskSnapshot(
            id: task.id,
            title: task.title,
            list: task.list,
            status: task.status,
            notes: task.notes,
            reminderDate: task.reminderDate,
            orderIndex: task.orderIndex
        )
        
        canUndo = true
        currentToastMessage = "To-do deleted."
        
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.currentToastMessage = nil
                }
            }
        }
    }
    
    public func undo() {
        guard let snapshot = lastDeleted else { return }
        
        let restored = TodoTask(
            id: snapshot.id,
            title: snapshot.title,
            list: snapshot.list,
            status: snapshot.status,
            notes: snapshot.notes,
            reminderDate: snapshot.reminderDate,
            orderIndex: snapshot.orderIndex
        )
        
        DataStore.shared.context.insert(restored)
        try? DataStore.shared.context.save()
        DataStore.shared.refreshTrigger = UUID()
        
        if restored.reminderDate != nil {
            ReminderService.shared.scheduleReminder(for: restored)
        }
        
        SoundManager.shared.play(.notification)
        
        lastDeleted = nil
        canUndo = false
        withAnimation(.easeOut(duration: 0.2)) {
            currentToastMessage = nil
        }
    }
}
