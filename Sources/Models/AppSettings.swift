import Foundation
import SwiftUI
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    public var soundEffectsEnabled: Bool {
        willSet { if newValue != soundEffectsEnabled { objectWillChange.send() } }
        didSet {
            guard oldValue != soundEffectsEnabled else { return }
            UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        }
    }
    
    public var soundPack: String {
        willSet { if newValue != soundPack { objectWillChange.send() } }
        didSet {
            guard oldValue != soundPack else { return }
            UserDefaults.standard.set(soundPack, forKey: "soundPack")
        }
    }
    
    public var allowInProgress: Bool {
        willSet { if newValue != allowInProgress { objectWillChange.send() } }
        didSet {
            guard oldValue != allowInProgress else { return }
            UserDefaults.standard.set(allowInProgress, forKey: "allowInProgress")
        }
    }
    
    public var addTaskPosition: String {
        willSet { if newValue != addTaskPosition { objectWillChange.send() } }
        didSet {
            guard oldValue != addTaskPosition else { return }
            UserDefaults.standard.set(addTaskPosition, forKey: "addTaskPosition")
        }
    }
    
    public var moveCompletedToBottom: Bool {
        willSet { if newValue != moveCompletedToBottom { objectWillChange.send() } }
        didSet {
            guard oldValue != moveCompletedToBottom else { return }
            UserDefaults.standard.set(moveCompletedToBottom, forKey: "moveCompletedToBottom")
            Task { @MainActor in
                DataStore.shared.reloadAll()
            }
        }
    }
    
    public var smartQuickAddEnabled: Bool {
        willSet { if newValue != smartQuickAddEnabled { objectWillChange.send() } }
        didSet {
            guard oldValue != smartQuickAddEnabled else { return }
            UserDefaults.standard.set(smartQuickAddEnabled, forKey: "smartQuickAddEnabled")
        }
    }
    
    public var showInMenuBar: Bool {
        willSet { if newValue != showInMenuBar { objectWillChange.send() } }
        didSet {
            guard oldValue != showInMenuBar else { return }
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }
    
    public var menuBarBadge: String {
        willSet { if newValue != menuBarBadge { objectWillChange.send() } }
        didSet {
            guard oldValue != menuBarBadge else { return }
            UserDefaults.standard.set(menuBarBadge, forKey: "menuBarBadge")
        }
    }
    
    public var appearanceMode: String {
        willSet { if newValue != appearanceMode { objectWillChange.send() } }
        didSet {
            guard oldValue != appearanceMode else { return }
            UserDefaults.standard.set(appearanceMode, forKey: "appearanceMode")
        }
    }
    
    public var selectedAppIcon: String {
        willSet { if newValue != selectedAppIcon { objectWillChange.send() } }
        didSet {
            guard oldValue != selectedAppIcon else { return }
            UserDefaults.standard.set(selectedAppIcon, forKey: "selectedAppIcon")
        }
    }
    
    public var archiveImmediately: Bool {
        willSet { if newValue != archiveImmediately { objectWillChange.send() } }
        didSet {
            guard oldValue != archiveImmediately else { return }
            UserDefaults.standard.set(archiveImmediately, forKey: "archiveImmediately")
        }
    }
    
    public var autoMoveRemindersToToday: Bool {
        willSet { if newValue != autoMoveRemindersToToday { objectWillChange.send() } }
        didSet {
            guard oldValue != autoMoveRemindersToToday else { return }
            UserDefaults.standard.set(autoMoveRemindersToToday, forKey: "autoMoveRemindersToToday")
        }
    }
    
    public var todayCapLimit: Int {
        willSet { if newValue != todayCapLimit { objectWillChange.send() } }
        didSet {
            guard oldValue != todayCapLimit else { return }
            UserDefaults.standard.set(todayCapLimit, forKey: "todayCapLimit")
        }
    }
    
    public var completionStreakCount: Int {
        willSet { if newValue != completionStreakCount { objectWillChange.send() } }
        didSet {
            guard oldValue != completionStreakCount else { return }
            UserDefaults.standard.set(completionStreakCount, forKey: "completionStreakCount")
        }
    }
    
    public var lastCompletedDateString: String? {
        willSet { if newValue != lastCompletedDateString { objectWillChange.send() } }
        didSet {
            guard oldValue != lastCompletedDateString else { return }
            UserDefaults.standard.set(lastCompletedDateString, forKey: "lastCompletedDateString")
        }
    }
    
    public static let streakDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        return df
    }()
    
    public var activeStreak: Int {
        guard let lastStr = lastCompletedDateString, completionStreakCount > 0 else { return 0 }
        let todayStr = Self.streakDateFormatter.string(from: Date())
        if lastStr == todayStr { return completionStreakCount }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            let yesterdayStr = Self.streakDateFormatter.string(from: yesterday)
            if lastStr == yesterdayStr { return completionStreakCount }
        }
        return 0
    }
    
    @discardableResult
    public func recordStreakIfTodayCleared(todayTasks: [TodoTask]) -> Bool {
        guard !todayTasks.isEmpty else { return false }
        let remaining = todayTasks.filter { $0.status != .completed }
        guard remaining.isEmpty else { return false }
        
        let todayStr = Self.streakDateFormatter.string(from: Date())
        if lastCompletedDateString == todayStr {
            return false
        }
        
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            let yesterdayStr = Self.streakDateFormatter.string(from: yesterday)
            if lastCompletedDateString == yesterdayStr {
                completionStreakCount += 1
            } else {
                completionStreakCount = 1
            }
        } else {
            completionStreakCount = 1
        }
        lastCompletedDateString = todayStr
        return true
    }
    
    private init() {
        let d = UserDefaults.standard
        self.soundEffectsEnabled = d.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        self.soundPack = d.string(forKey: "soundPack") ?? "BubblePop"
        self.allowInProgress = d.object(forKey: "allowInProgress") as? Bool ?? true
        self.addTaskPosition = d.string(forKey: "addTaskPosition") ?? "bottom"
        self.moveCompletedToBottom = d.object(forKey: "moveCompletedToBottom") as? Bool ?? true
        self.smartQuickAddEnabled = d.object(forKey: "smartQuickAddEnabled") as? Bool ?? true
        self.showInMenuBar = d.object(forKey: "showInMenuBar") as? Bool ?? true
        self.menuBarBadge = d.string(forKey: "menuBarBadge") ?? "remaining"
        self.appearanceMode = d.string(forKey: "appearanceMode") ?? "system"
        self.selectedAppIcon = d.string(forKey: "selectedAppIcon") ?? "Grind Dark"
        self.archiveImmediately = d.object(forKey: "archiveImmediately") as? Bool ?? false
        self.autoMoveRemindersToToday = d.object(forKey: "autoMoveRemindersToToday") as? Bool ?? true
        self.todayCapLimit = d.object(forKey: "todayCapLimit") as? Int ?? 5
        self.completionStreakCount = d.integer(forKey: "completionStreakCount")
        self.lastCompletedDateString = d.string(forKey: "lastCompletedDateString")
    }
    
    public var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
