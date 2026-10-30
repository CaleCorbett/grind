import Foundation
import SwiftUI
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    @Published public var soundEffectsEnabled: Bool {
        didSet {
            guard oldValue != soundEffectsEnabled else { return }
            UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        }
    }
    
    @Published public var soundPack: String {
        didSet {
            guard oldValue != soundPack else { return }
            UserDefaults.standard.set(soundPack, forKey: "soundPack")
        }
    }
    
    @Published public var allowInProgress: Bool {
        didSet {
            guard oldValue != allowInProgress else { return }
            UserDefaults.standard.set(allowInProgress, forKey: "allowInProgress")
        }
    }
    
    @Published public var addTaskPosition: String {
        didSet {
            guard oldValue != addTaskPosition else { return }
            UserDefaults.standard.set(addTaskPosition, forKey: "addTaskPosition")
        }
    }
    
    @Published public var moveCompletedToBottom: Bool {
        didSet {
            guard oldValue != moveCompletedToBottom else { return }
            UserDefaults.standard.set(moveCompletedToBottom, forKey: "moveCompletedToBottom")
            Task { @MainActor in
                DataStore.shared.reloadAll()
            }
        }
    }
    
    @Published public var smartQuickAddEnabled: Bool {
        didSet {
            guard oldValue != smartQuickAddEnabled else { return }
            UserDefaults.standard.set(smartQuickAddEnabled, forKey: "smartQuickAddEnabled")
        }
    }
    
    @Published public var showInMenuBar: Bool {
        didSet {
            guard oldValue != showInMenuBar else { return }
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }
    
    @Published public var menuBarBadge: String {
        didSet {
            guard oldValue != menuBarBadge else { return }
            UserDefaults.standard.set(menuBarBadge, forKey: "menuBarBadge")
        }
    }
    
    @Published public var appearanceMode: String {
        didSet {
            guard oldValue != appearanceMode else { return }
            UserDefaults.standard.set(appearanceMode, forKey: "appearanceMode")
        }
    }
    
    @Published public var selectedAppIcon: String {
        didSet {
            guard oldValue != selectedAppIcon else { return }
            UserDefaults.standard.set(selectedAppIcon, forKey: "selectedAppIcon")
        }
    }
    
    @Published public var archiveImmediately: Bool {
        didSet {
            guard oldValue != archiveImmediately else { return }
            UserDefaults.standard.set(archiveImmediately, forKey: "archiveImmediately")
        }
    }
    
    @Published public var autoMoveRemindersToToday: Bool {
        didSet {
            guard oldValue != autoMoveRemindersToToday else { return }
            UserDefaults.standard.set(autoMoveRemindersToToday, forKey: "autoMoveRemindersToToday")
        }
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
    }
    
    public var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
