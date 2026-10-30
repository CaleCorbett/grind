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
    
    private var menuBarInsertedBinding: Binding<Bool> {
        Binding(
            get: { settings.showInMenuBar },
            set: { newValue in
                if settings.showInMenuBar != newValue {
                    settings.showInMenuBar = newValue
                }
            }
        )
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
        MenuBarExtra("Grind", systemImage: menuBarSystemImage, isInserted: menuBarInsertedBinding) {
            MenuBarTodayView()
                .modelContainer(DataStore.shared.container)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var menuBarSystemImage: String {
        let count: Int
        switch settings.menuBarBadge {
        case "total":
            count = store.todayTotalCount
        case "remaining":
            count = store.todayRemainingCount
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
