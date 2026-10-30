import SwiftUI

public struct MenuBarTodayView: View {
    @ObservedObject private var store = DataStore.shared
    @State private var quickText: String = ""
    
    public init() {}
    
    private var completedCount: Int {
        todayTasks.filter { $0.status == .completed }.count
    }
    
    private var completionFraction: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(todayTasks.count)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Text("Today")
                    .font(.geist(.bold, size: 15))
                    .foregroundColor(GrindColors.primary)
                
                Spacer()
                
                HStack(spacing: 5) {
                    if !todayTasks.isEmpty {
                        ZStack {
                            Circle()
                                .stroke(GrindColors.primary.opacity(0.16), lineWidth: 1.8)
                                .frame(width: 10, height: 10)
                            Circle()
                                .trim(from: 0, to: completionFraction)
                                .stroke(GrindColors.primary, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 10, height: 10)
                                .animation(GrindTheme.easeSpring, value: completionFraction)
                        }
                    }
                    Text("\(completedCount)/\(todayTasks.count)")
                        .font(.geist(.mono, size: 11))
                        .foregroundColor(GrindColors.secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(GrindColors.hair)
                .clipShape(Capsule())
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
                            let isCompleted = (task.status == .completed)
                            HStack(spacing: 9) {
                                StatusToggleView(status: task.status) {
                                    store.toggleTaskStatus(task)
                                }
                                Text(task.title)
                                    .font(.geist(.medium, size: 13))
                                    .foregroundColor(isCompleted ? GrindColors.secondary : GrindColors.primary)
                                    .lineLimit(1)
                                    .overlay(alignment: .leading) {
                                        Rectangle()
                                            .fill(GrindColors.secondary)
                                            .frame(height: 1.2)
                                            .scaleEffect(x: isCompleted ? 1.0 : 0.0, y: 1.0, anchor: .leading)
                                            .animation(GrindTheme.easeSpring, value: isCompleted)
                                            .allowsHitTesting(false)
                                    }
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
            
            // Inline Add with Smart Parsing
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(GrindColors.secondary)
                TextField("Add to Today...", text: $quickText)
                    .textFieldStyle(.plain)
                    .font(.geist(.regular, size: 13))
                    .onSubmit {
                        let trimmed = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            let parsed = QuickAddParser.parse(trimmed)
                            let title = parsed.cleanTitle.isEmpty ? trimmed : parsed.cleanTitle
                            store.addTask(title: title, to: .today, reminderDate: parsed.reminderDate)
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
                    if let window = NSApp.windows.first {
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
        .frame(width: 290)
        .background(GrindColors.cardToday)
    }
    
    private var todayTasks: [TodoTask] {
        store.todayTasks
    }
}
