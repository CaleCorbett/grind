import Foundation

public struct RecurrenceService {
    public static func nextDueDate(for rule: String, from baseDate: Date = Date()) -> Date {
        let cal = Calendar.current
        let lower = rule.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch lower {
        case "daily", "every day":
            return cal.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate.addingTimeInterval(86400)
            
        case "weekdays", "every weekday":
            var next = cal.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate.addingTimeInterval(86400)
            while cal.isDateInWeekend(next) {
                next = cal.date(byAdding: .day, value: 1, to: next) ?? next.addingTimeInterval(86400)
            }
            return next
            
        case "weekly", "every week":
            return cal.date(byAdding: .day, value: 7, to: baseDate) ?? baseDate.addingTimeInterval(7 * 86400)
            
        case "monthly", "every month":
            return cal.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate.addingTimeInterval(30 * 86400)
            
        default:
            if lower.hasPrefix("every ") {
                let dayName = String(lower.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                let weekdayMap: [String: Int] = [
                    "sunday": 1, "sun": 1,
                    "monday": 2, "mon": 2,
                    "tuesday": 3, "tue": 3,
                    "wednesday": 4, "wed": 4,
                    "thursday": 5, "thu": 5,
                    "friday": 6, "fri": 6,
                    "saturday": 7, "sat": 7
                ]
                if let targetWeekday = weekdayMap[dayName] {
                    var current = cal.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate.addingTimeInterval(86400)
                    for _ in 0..<7 {
                        let comp = cal.component(.weekday, from: current)
                        if comp == targetWeekday {
                            return current
                        }
                        current = cal.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
                    }
                }
            }
            return cal.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate.addingTimeInterval(86400)
        }
    }
    
    public static func displayString(for rule: String) -> String {
        let lower = rule.lowercased()
        switch lower {
        case "daily", "every day": return "Daily"
        case "weekdays", "every weekday": return "Weekdays"
        case "weekly", "every week": return "Weekly"
        case "monthly", "every month": return "Monthly"
        default:
            return rule.capitalized
        }
    }
}

