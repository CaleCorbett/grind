import Foundation
import SwiftUI
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    @AppStorage("soundEffectsEnabled") public var soundEffectsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("soundPack") public var soundPack: String = "BubblePop" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("allowInProgress") public var allowInProgress: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("addTaskPosition") public var addTaskPosition: String = "bottom" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("moveCompletedToBottom") public var moveCompletedToBottom: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("smartQuickAddEnabled") public var smartQuickAddEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("showInMenuBar") public var showInMenuBar: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("menuBarBadge") public var menuBarBadge: String = "remaining" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("appearanceMode") public var appearanceMode: String = "system" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("selectedAppIcon") public var selectedAppIcon: String = "Check Dat" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("archiveImmediately") public var archiveImmediately: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("autoMoveRemindersToToday") public var autoMoveRemindersToToday: Bool = true {
        willSet { objectWillChange.send() }
    }
    
    private init() {}
    
    public var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
