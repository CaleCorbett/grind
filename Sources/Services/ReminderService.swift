import Foundation
@preconcurrency import UserNotifications

@MainActor
public final class ReminderService {
    public static let shared = ReminderService()
    
    private init() {}
    
    /// Safely returns `UNUserNotificationCenter.current()` only when running inside a valid `.app` bundle.
    /// Calling `UNUserNotificationCenter.current()` from a bare executable (`swift run` / CLI test) throws
    /// an uncaught Objective-C `NSInternalInconsistencyException` (`bundleProxyForCurrentProcess is nil`).
    private var notificationCenter: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil,
              Bundle.main.bundleURL.pathExtension == "app" else {
            return nil
        }
        return UNUserNotificationCenter.current()
    }
    
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard let center = notificationCenter else {
            completion?(false)
            return
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            Task { @MainActor in
                completion?(granted)
            }
        }
    }
    
    public func scheduleReminder(for task: TodoTask) {
        guard let reminderDate = task.reminderDate, reminderDate > Date(),
              let center = notificationCenter else { return }
        let taskId = task.id.uuidString
        let taskTitle = task.title
        let listTitle = task.list.title
        
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                Task { @MainActor in
                    ReminderService.shared.addNotificationRequest(id: taskId, title: taskTitle, listTitle: listTitle, at: reminderDate)
                }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
        guard let center = notificationCenter else { return }
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
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            }
        }
    }
    
    public func cancelReminder(for task: TodoTask) {
        guard task.reminderDate != nil, let center = notificationCenter else { return }
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    public func cancelReminders(for tasks: [TodoTask]) {
        let ids = tasks.filter { $0.reminderDate != nil }.map { $0.id.uuidString }
        guard !ids.isEmpty, let center = notificationCenter else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
