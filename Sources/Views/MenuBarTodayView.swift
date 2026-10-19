import SwiftUI

public struct MenuBarTodayView: View {
    @ObservedObject private var store = DataStore.shared
    @State private var quickText: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Today")
                    .font(.geist(.bold, size: 15))
                    .foregroundColor(GrindColors.primary)
                Spacer()
                Text("\(todayTasks.count) tasks")
                    .font(.geist(.regular, size: 12))
                    .foregroundColor(GrindColors.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            
            Divider()
                .background(GrindColors.hair)
            
            // Task Rows
            if todayTasks.isEmpty {
                VStack(spacing: 4) {
                    Text("No tasks for Today")
                        .font(.geist(.medium, size: 13))
                        .foregroundColor(GrindColors.secondary)
                    Text("You're all caught up!")
                        .font(.geist(.regular, size: 11))
                        .foregroundColor(GrindColors.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(todayTasks) { task in
                            HStack(spacing: 8) {
                                StatusToggleView(status: task.status) {
                                    store.toggleTaskStatus(task)
                                }
                                Text(task.title)
                                    .font(.geist(.regular, size: 13))
                                    .foregroundColor(task.status == .completed ? GrindColors.secondary : GrindColors.primary)
                                    .strikethrough(task.status == .completed)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            
            Divider()
                .background(GrindColors.hair)
            
            // Inline Add
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                    .foregroundColor(GrindColors.secondary)
                TextField("Add to Today...", text: $quickText)
                    .textFieldStyle(.plain)
                    .font(.geist(.regular, size: 13))
                    .onSubmit {
                        let trimmed = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            store.addTask(title: trimmed, to: .today)
                            quickText = ""
                        }
                    }
            }
            .padding(.horizontal, 14)
            
            Divider()
                .background(GrindColors.hair)
            
            // App Controls
            HStack {
                Button("Open Grind") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.contains("Grind") }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.plain)
                .font(.geist(.medium, size: 12))
                .foregroundColor(GrindColors.primary)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.geist(.regular, size: 12))
                .foregroundColor(GrindColors.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(GrindColors.cardToday)
    }
    
    private var todayTasks: [TodoTask] {
        _ = store.refreshTrigger
        return store.tasks(for: .today)
    }
}
