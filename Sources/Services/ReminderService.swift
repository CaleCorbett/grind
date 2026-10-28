import Foundation
import UserNotifications

@MainActor
public final class ReminderService {
    public static let shared = ReminderService()
    
    private init() {}
    
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            Task { @MainActor in
                completion?(granted)
            }
        }
    }
    
    public func scheduleReminder(for task: TodoTask) {
        guard let reminderDate = task.reminderDate, reminderDate > Date() else { return }
        let taskId = task.id.uuidString
        let taskTitle = task.title
        let listTitle = task.list.title
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                Task { @MainActor in
                    ReminderService.shared.addNotificationRequest(id: taskId, title: taskTitle, listTitle: listTitle, at: reminderDate)
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        Task { @MainActor in
                            ReminderService.shared.addNotificationRequest(id: taskId, title: taskTitle, listTitle: listTitle, at: reminderDate)
                        }
                    } else if let error = error {
                        print("Notification authorization denied or error: \(error)")
                    }
                }
            case .denied:
                print("Notifications are denied by the user.")
            @unknown default:
                break
            }
        }
    }
    
    private func addNotificationRequest(id: String, title: String, listTitle: String, at reminderDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Grind"
        content.subtitle = listTitle
        content.body = title
        content.sound = .default
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            }
        }
    }
    
    public func cancelReminder(for task: TodoTask) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
