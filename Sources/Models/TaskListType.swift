import Foundation

public enum TaskListType: String, Codable, CaseIterable, Identifiable, Sendable {
    case today = "today"
    case next = "next"
    case someday = "someday"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .today: return "Today"
        case .next: return "Next"
        case .someday: return "Someday"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .today: return "Daily focus"
        case .next: return "Upcoming to-dos"
        case .someday: return "Ideas & aspirations"
        }
    }
    
    public var shortcutNumber: Int {
        switch self {
        case .today: return 1
        case .next: return 2
        case .someday: return 3
        }
    }
    
    public var shortcutDisplay: String {
        "⌘\(shortcutNumber)"
    }
    
    public var iconName: String {
        switch self {
        case .today: return "sun.max.fill"
        case .next: return "arrow.right.circle.fill"
        case .someday: return "sparkles"
        }
    }
    
    /// Primary 1-click triage target shown on hover
    public var primaryQuickMoveTarget: TaskListType {
        switch self {
        case .today: return .next
        case .next: return .today
        case .someday: return .today
        }
    }
}
