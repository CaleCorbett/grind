import Foundation

public enum TaskStatus: Int, Codable, CaseIterable, Identifiable {
    case incomplete = 0
    case inProgress = 1
    case completed = 2
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .incomplete: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Done"
        }
    }
    
    public func nextStatus(allowInProgress: Bool) -> TaskStatus {
        if allowInProgress {
            switch self {
            case .incomplete: return .inProgress
            case .inProgress: return .completed
            case .completed: return .incomplete
            }
        } else {
            switch self {
            case .incomplete, .inProgress: return .completed
            case .completed: return .incomplete
            }
        }
    }
}
