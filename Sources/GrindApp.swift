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
                .onReceive(hotKey.$shouldOpenQuickAdd) { shouldOpen in
                    if shouldOpen {
                        hotKey.shouldOpenQuickAdd = false
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        
        // Settings Window (Cmd+,)
        Settings {
            SettingsView()
                .preferredColorScheme(settings.preferredColorScheme)
        }
        
        // macOS Menu Bar Extra
        MenuBarExtra("Grind", systemImage: menuBarSystemImage) {
            MenuBarTodayView()
                .modelContainer(DataStore.shared.container)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var menuBarSystemImage: String {
        let remaining = store.tasks(for: .today).filter { $0.status != .completed }.count
        if settings.menuBarBadge == "none" || remaining == 0 {
            return "checkmark.square"
        }
        if remaining <= 50 {
            return "\(remaining).circle"
        }
        return "checkmark.circle.fill"
    }
}
