import Foundation

public struct ParsedQuickAdd {
    public var cleanTitle: String
    public var targetList: TaskListType
    public var isEvening: Bool
    public var reminderDate: Date?
    public var matchedDateString: String?
    public var recurrenceRule: String?
    
    public init(
        cleanTitle: String,
        targetList: TaskListType,
        isEvening: Bool = false,
        reminderDate: Date? = nil,
        matchedDateString: String? = nil,
        recurrenceRule: String? = nil
    ) {
        self.cleanTitle = cleanTitle
        self.targetList = targetList
        self.isEvening = isEvening
        self.reminderDate = reminderDate
        self.matchedDateString = matchedDateString
        self.recurrenceRule = recurrenceRule
    }
}

public final class QuickAddParser {
    private static let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    
    public static func parse(_ rawInput: String) -> ParsedQuickAdd {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedQuickAdd(cleanTitle: "", targetList: .today, isEvening: false, reminderDate: nil, matchedDateString: nil)
        }
        
        guard AppSettings.shared.smartQuickAddEnabled else {
            return ParsedQuickAdd(cleanTitle: trimmed, targetList: .today, isEvening: false, reminderDate: nil, matchedDateString: nil)
        }
        
        var working = trimmed
        var targetList: TaskListType = .today
        var isEvening: Bool = false
        var reminderDate: Date? = nil
        var matchedDateString: String? = nil
        var recurrenceRule: String? = nil
        
        let lower = working.lowercased()
        
        // 1. Recurrence detection (extracted before date detector to avoid partial date collision)
        let recurrencePatterns: [(String, String)] = [
            ("\\b(every\\s+weekday|weekdays)\\b", "weekdays"),
            ("\\b(every\\s+day|daily)\\b", "daily"),
            ("\\b(every\\s+week|weekly)\\b", "weekly"),
            ("\\b(every\\s+month|monthly)\\b", "monthly"),
            ("\\b(every\\s+monday)\\b", "every monday"),
            ("\\b(every\\s+tuesday)\\b", "every tuesday"),
            ("\\b(every\\s+wednesday)\\b", "every wednesday"),
            ("\\b(every\\s+thursday)\\b", "every thursday"),
            ("\\b(every\\s+friday)\\b", "every friday"),
            ("\\b(every\\s+saturday)\\b", "every saturday"),
            ("\\b(every\\s+sunday)\\b", "every sunday")
        ]
        
        for (pattern, rule) in recurrencePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: working, options: [], range: NSRange(location: 0, length: working.utf16.count)) != nil {
                recurrenceRule = rule
                working = removePattern(working, pattern: pattern)
                break
            }
        }
        
        // 2. Explicit list keywords & evening keyword
        if lower.contains("tonight") || lower.contains("this evening") || lower.contains("evening") {
            isEvening = true
            targetList = .today
            working = removePattern(working, pattern: "\\b(tonight|this\\s+evening|evening)\\b")
        }
        
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
        
        // 2. Natural language date parsing using cached NSDataDetector (bounded length for responsiveness)
        if working.count <= 280, let detector = Self.dateDetector {
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
            isEvening: isEvening,
            reminderDate: reminderDate,
            matchedDateString: matchedDateString,
            recurrenceRule: recurrenceRule
        )
    }
    
    private static func removePattern(_ string: String, pattern: String) -> String {
        return string.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
    }
}
