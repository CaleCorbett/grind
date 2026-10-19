import Foundation

public struct ParsedQuickAdd {
    public var cleanTitle: String
    public var targetList: TaskListType
    public var reminderDate: Date?
    public var matchedDateString: String?
}

public final class QuickAddParser {
    public static func parse(_ rawInput: String) -> ParsedQuickAdd {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedQuickAdd(cleanTitle: "", targetList: .today, reminderDate: nil, matchedDateString: nil)
        }
        
        guard AppSettings.shared.smartQuickAddEnabled else {
            return ParsedQuickAdd(cleanTitle: trimmed, targetList: .today, reminderDate: nil, matchedDateString: nil)
        }
        
        var working = trimmed
        var targetList: TaskListType = .today
        var reminderDate: Date? = nil
        var matchedDateString: String? = nil
        
        let lower = working.lowercased()
        
        // 1. Explicit list keywords
        if lower.contains("someday") {
            targetList = .someday
            working = removePattern(working, pattern: "\\b(on\\s+)?someday\\b")
        } else if lower.contains("next") && (lower.contains("list") || lower.contains("card")) {
            targetList = .next
            working = removePattern(working, pattern: "\\b(to\\s+|on\\s+)?next(\\s+(list|card))?\\b")
        } else if lower.contains("today") && (lower.contains("list") || lower.contains("card")) {
            targetList = .today
            working = removePattern(working, pattern: "\\b(to\\s+|on\\s+)?today(\\s+(list|card))?\\b")
        }
        
        // 2. Natural language date parsing using NSDataDetector
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: working, options: [], range: NSRange(location: 0, length: working.utf16.count))
            
            // Prefer the last date match (usually at the end of phrase, e.g. "Buy coffee Friday 3pm")
            if let lastMatch = matches.last, let detectedDate = lastMatch.date {
                reminderDate = detectedDate
                if let range = Range(lastMatch.range, in: working) {
                    matchedDateString = String(working[range])
                    working.removeSubrange(range)
                }
                
                // Determine target list based on date proximity
                let calendar = Calendar.current
                if calendar.isDateInToday(detectedDate) {
                    targetList = .today
                } else if detectedDate > Date() {
                    targetList = .next
                }
            }
        }
        
        // 3. Clean up title
        var clean = working
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",.-@"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if clean.isEmpty {
            clean = trimmed
        } else {
            // Capitalize first letter
            clean = clean.prefix(1).uppercased() + clean.dropFirst()
        }
        
        return ParsedQuickAdd(
            cleanTitle: clean,
            targetList: targetList,
            reminderDate: reminderDate,
            matchedDateString: matchedDateString
        )
    }
    
    private static func removePattern(_ string: String, pattern: String) -> String {
        return string.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
    }
}
