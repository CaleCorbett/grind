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
                .onOpenURL { url in
                    handleIncomingURL(url)
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
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "grind" else { return }
        let host = url.host?.lowercased() ?? url.pathComponents.first?.lowercased()
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let queryItems = components.queryItems ?? []
        
        switch host {
        case "add":
            let title = queryItems.first(where: { $0.name == "title" })?.value ?? ""
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            let listParam = queryItems.first(where: { $0.name == "list" })?.value?.lowercased() ?? "today"
            let list = TaskListType(rawValue: listParam) ?? .today
            let notes = queryItems.first(where: { $0.name == "notes" })?.value
            let evening = queryItems.first(where: { $0.name == "evening" })?.value?.lowercased() == "true"
            let recurrence = queryItems.first(where: { $0.name == "repeat" || $0.name == "recurrence" })?.value
            
            store.addTask(title: title, to: list, notes: notes, isEvening: evening, recurrenceRule: recurrence)
            UndoToastManager.shared.showInfo("Added via URL: “\(title)”", targetList: list)
            
        case "show":
            let listParam = queryItems.first(where: { $0.name == "list" })?.value?.lowercased() ?? "today"
            if let list = TaskListType(rawValue: listParam) {
                UndoToastManager.shared.requestedFocusList = list
            }
            
        default:
            break
        }
    }
}
