import Foundation
import SwiftUI
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    @AppStorage("soundEffectsEnabled") public var soundEffectsEnabled: Bool = true
    @AppStorage("soundPack") public var soundPack: String = "BubblePop"
    @AppStorage("allowInProgress") public var allowInProgress: Bool = true
    @AppStorage("addTaskPosition") public var addTaskPosition: String = "bottom"
    @AppStorage("moveCompletedToBottom") public var moveCompletedToBottom: Bool = true
    @AppStorage("smartQuickAddEnabled") public var smartQuickAddEnabled: Bool = true
    @AppStorage("showInMenuBar") public var showInMenuBar: Bool = true
    @AppStorage("menuBarBadge") public var menuBarBadge: String = "remaining"
    @AppStorage("appearanceMode") public var appearanceMode: String = "system"
    @AppStorage("selectedAppIcon") public var selectedAppIcon: String = "Check Dat"
    @AppStorage("archiveImmediately") public var archiveImmediately: Bool = false
    @AppStorage("autoMoveRemindersToToday") public var autoMoveRemindersToToday: Bool = true
    
    private init() {}
    
    public var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
