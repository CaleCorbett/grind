import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    public init() {}
    
    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            soundsTab
                .tabItem {
                    Label("Sounds", systemImage: "speaker.wave.2")
                }
            
            quickAddTab
                .tabItem {
                    Label("Quick-Add", systemImage: "plus.circle")
                }
            
            menuBarTab
                .tabItem {
                    Label("Menu Bar", systemImage: "menubar.rectangle")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 420)
        .padding(10)
    }
    
    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section("Status Steps") {
                Toggle("Enable 'In Progress' State", isOn: $settings.allowInProgress)
                Text("When enabled, checking a to-do cycles: To Do → In Progress (half pie) → Done.")
                    .font(.caption)
                    .foregroundColor(GrindColors.secondary)
            }
            
            Section("Task Placement & Auto-Move") {
                Picker("New To-Dos Added At", selection: $settings.addTaskPosition) {
                    Text("Bottom of List").tag("bottom")
                    Text("Top of List").tag("top")
                }
                .pickerStyle(.radioGroup)
                
                Toggle("Move Completed To-Dos to Bottom", isOn: $settings.moveCompletedToBottom)
                
                Toggle("Auto-Move Reminders to Today", isOn: $settings.autoMoveRemindersToToday)
                Text("Any to-do on Next or Someday with a reminder due today slides onto Today automatically.")
                    .font(.caption)
                    .foregroundColor(GrindColors.secondary)
                
                Toggle("Archive Completed Immediately", isOn: $settings.archiveImmediately)
            }
            
            Section("Appearance") {
                Picker("Theme", selection: $settings.appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                
                Picker("App Icon", selection: $settings.selectedAppIcon) {
                    Text("Grind Dark (Default)").tag("Grind Dark")
                    Text("Grind Light").tag("Grind Light")
                    Text("Grind Minimal").tag("Grind Minimal")
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Sounds Tab
    private var soundsTab: some View {
        Form {
            Section("Sound Feedback") {
                Toggle("Play Sound Effects", isOn: $settings.soundEffectsEnabled)
                Text("Tactile sound effects on task completion, status progress, and deletion.")
                    .font(.caption)
                    .foregroundColor(GrindColors.secondary)
            }
            
            Section("Preview Sounds") {
                HStack(spacing: 12) {
                    Button("Completed") {
                        SoundManager.shared.play(.completed)
                    }
                    Button("In Progress") {
                        SoundManager.shared.play(.inProgress)
                    }
                    Button("Deleted") {
                        SoundManager.shared.play(.deleted)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Quick Add Tab
    private var quickAddTab: some View {
        Form {
            Section("Global Capture") {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    Text("⌃⌥Space")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(GrindColors.hair)
                        .cornerRadius(6)
                }
                Text("Press anywhere across macOS to summon the Quick-Add HUD.")
                    .font(.caption)
                    .foregroundColor(GrindColors.secondary)
            }
            
            Section("Smart Quick-Add") {
                Toggle("Enable Smart Quick-Add", isOn: $settings.smartQuickAddEnabled)
                Text("Automatically detects dates, times, and lists. E.g. 'dentist Friday 3pm' sets a reminder for Friday 3:00 PM and puts it on Next.")
                    .font(.caption)
                    .foregroundColor(GrindColors.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Menu Bar Tab
    private var menuBarTab: some View {
        Form {
            Section("Menu Bar Extra") {
                Toggle("Show Grind in Menu Bar", isOn: $settings.showInMenuBar)
                Text("Keep Today's to-dos accessible right from your Mac's menu bar.")
                    .font(.caption)
                    .foregroundColor(GrindColors.secondary)
            }
            
            Section("Badge Count") {
                Picker("Menu Bar Icon Shows", selection: $settings.menuBarBadge) {
                    Text("Remaining to-dos today").tag("remaining")
                    Text("Total to-dos today").tag("total")
                    Text("Icon only (No count)").tag("none")
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
            
            Text("Grind")
                .font(.geist(.bold, size: 22))
                .foregroundColor(GrindColors.primary)
            
            Text("Version 1.0.0")
                .font(.geist(.regular, size: 12))
                .foregroundColor(GrindColors.secondary)
            
            Text("Focus. Check. Repeat.")
                .font(.geist(.medium, size: 14))
                .foregroundColor(GrindColors.primary)
            
            Text("Three lists. Zero clutter. Stop drowning in endless lists and know what to do today.")
                .font(.geist(.regular, size: 12))
                .foregroundColor(GrindColors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Text("100% Native macOS App")
                .font(.caption2)
                .foregroundColor(GrindColors.secondary.opacity(0.7))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
