import Foundation
import SwiftData

@MainActor
public final class AutoMoveService {
    public static let shared = AutoMoveService()
    
    private init() {}
    
    public func performDailySweep() {
        let calendar = Calendar.current
        let today = Date()
        
        let descriptor = FetchDescriptor<TodoTask>(predicate: #Predicate { !$0.isArchived })
        guard let activeTasks = try? DataStore.shared.context.fetch(descriptor) else { return }
        
        var hasChanges = false
        
        for task in activeTasks {
            // 1. Move tasks from Next or Someday to Today if reminder is due today or past
            if AppSettings.shared.autoMoveRemindersToToday && task.list != .today, let reminder = task.reminderDate {
                if calendar.isDateInToday(reminder) || reminder < today {
                    task.list = .today
                    hasChanges = true
                }
            }
            
            // 2. Archive completed tasks if archiveImmediately is enabled
            if AppSettings.shared.archiveImmediately && task.status == .completed && !task.isArchived {
                task.isArchived = true
                hasChanges = true
            }
        }
        
        if hasChanges {
            try? DataStore.shared.context.save()
            DataStore.shared.reloadAll()
        }
    }
}
