import Foundation

public enum TaskListType: String, Codable, CaseIterable, Identifiable {
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
        case .today: return "Your focused daily list. Short and ruthless."
        case .next: return "What's coming up soon without cluttering today."
        case .someday: return "Ideas, aspirations, and maybe-laters."
        }
    }
}
