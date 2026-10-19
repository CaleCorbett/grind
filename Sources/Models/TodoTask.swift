import Foundation
import SwiftData

@Model
public final class TodoTask: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var rawList: String
    public var rawStatus: Int
    public var notes: String?
    public var reminderDate: Date?
    public var creationDate: Date
    public var completionDate: Date?
    public var orderIndex: Int
    public var isArchived: Bool

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
        isArchived: Bool = false
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
}
