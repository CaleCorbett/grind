import Foundation
import SwiftData

@Model
public final class TodoTask: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var rawList: String = "today"
    public var rawStatus: Int = 0
    public var notes: String?
    public var reminderDate: Date?
    public var creationDate: Date = Date()
    public var completionDate: Date?
    public var orderIndex: Int = 0
    public var isArchived: Bool = false
    public var recurrenceRule: String?
    public var isEvening: Bool = false
    public var checklistJSON: String?
    public var lastTouchedDate: Date?
    public var focusSecondsLogged: Int = 0
    public var deletedDate: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        list: TaskListType = .today,
        status: TaskStatus = .incomplete,
        notes: String? = nil,
        reminderDate: Date? = nil,
        creationDate: Date = Date(),
        completionDate: Date? = nil,
        orderIndex: Int = 0,
        isArchived: Bool = false,
        recurrenceRule: String? = nil,
        isEvening: Bool = false,
        checklistJSON: String? = nil,
        lastTouchedDate: Date? = nil,
        focusSecondsLogged: Int = 0,
        deletedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.rawList = list.rawValue
        self.rawStatus = status.rawValue
        self.notes = notes
        self.reminderDate = reminderDate
        self.creationDate = creationDate
        self.completionDate = completionDate
        self.orderIndex = orderIndex
        self.isArchived = isArchived
        self.recurrenceRule = recurrenceRule
        self.isEvening = isEvening
        self.checklistJSON = checklistJSON
        self.lastTouchedDate = lastTouchedDate ?? creationDate
        self.focusSecondsLogged = focusSecondsLogged
        self.deletedDate = deletedDate
    }

    public var list: TaskListType {
        get { TaskListType(rawValue: rawList) ?? .today }
        set { rawList = newValue.rawValue }
    }

    public var status: TaskStatus {
        get { TaskStatus(rawValue: rawStatus) ?? .incomplete }
        set {
            rawStatus = newValue.rawValue
            if newValue == .completed {
                completionDate = Date()
            } else {
                completionDate = nil
            }
        }
    }
    
    public var isDeleted: Bool {
        deletedDate != nil
    }
    
    public var isStaleSomeday: Bool {
        guard list == .someday, status != .completed, !isArchived, !isDeleted else { return false }
        let touchDate = lastTouchedDate ?? creationDate
        let staleThreshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date().addingTimeInterval(-30 * 86400)
        return touchDate < staleThreshold
    }
    
    public var daysUntouched: Int {
        let touchDate = lastTouchedDate ?? creationDate
        let diff = Calendar.current.dateComponents([.day], from: touchDate, to: Date())
        return max(0, diff.day ?? 0)
    }
    
    public var checklist: [ChecklistItem] {
        get {
            guard let json = checklistJSON, let data = json.data(using: .utf8) else { return [] }
            if let items = try? JSONDecoder().decode([ChecklistItem].self, from: data) {
                return items
            }
            if let strings = try? JSONDecoder().decode([String].self, from: data) {
                return strings.map { ChecklistItem(title: $0) }
            }
            return []
        }
        set {
            if newValue.isEmpty {
                checklistJSON = nil
            } else if let data = try? JSONEncoder().encode(newValue),
                      let str = String(data: data, encoding: .utf8) {
                checklistJSON = str
            }
        }
    }
    
    public var checklistSummary: (completed: Int, total: Int)? {
        let items = checklist
        guard !items.isEmpty else { return nil }
        let completed = items.filter(\.isCompleted).count
        return (completed, items.count)
    }
}

public struct ChecklistItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}
