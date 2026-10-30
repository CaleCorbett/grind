import SwiftUI
import SwiftData

@main
struct GrindApp: App {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var store = DataStore.shared
    @StateObject private var hotKey = GlobalHotKeyManager.shared
    
    init() {
        FontManager.shared.registerCustomFonts()
    }
    
    var body: some Scene {
        // Main Application Window
        WindowGroup {
            MainView()
                .modelContainer(DataStore.shared.container)
                .frame(minWidth: 880, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        
        // Settings Window (Cmd+,)
        Settings {
            SettingsView()
                .preferredColorScheme(settings.preferredColorScheme)
        }
        
        // macOS Menu Bar Extra
        MenuBarExtra("Grind", systemImage: menuBarSystemImage, isInserted: $settings.showInMenuBar) {
            MenuBarTodayView()
                .modelContainer(DataStore.shared.container)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var menuBarSystemImage: String {
        _ = store.refreshTrigger
        let today = store.tasks(for: .today)
        let count: Int
        switch settings.menuBarBadge {
        case "total":
            count = today.count
        case "remaining":
            count = today.filter { $0.status != .completed }.count
        default:
            count = 0
        }
        
        if settings.menuBarBadge == "none" || count == 0 {
            return "checkmark.square"
        }
        if count <= 50 {
            return "\(count).circle"
        }
        return "checkmark.circle.fill"
    }
}
