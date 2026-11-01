import SwiftUI

public struct StaleReviewSheet: View {
    @ObservedObject private var store = DataStore.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Someday Ideas Review")
                            .font(.geist(.bold, size: 16))
                            .foregroundColor(GrindColors.primary)
                        
                        Text("Untouched for 30+ days. Rekindle them, promote to active lists, or purge.")
                            .font(.geist(.regular, size: 12))
                            .foregroundColor(GrindColors.secondary)
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.geist(.semiBold, size: 13))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(GrindColors.primary)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)
            
            Divider()
                .background(GrindColors.hair)
            
            let staleTasks = store.staleSomedayTasks
            
            if staleTasks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 34))
                        .foregroundColor(.purple)
                    Text("Your Someday list is fresh.")
                        .font(.geist(.semiBold, size: 15))
                        .foregroundColor(GrindColors.primary)
                    Text("No stale ideas lingering untouched for over a month.")
                        .font(.geist(.regular, size: 13))
                        .foregroundColor(GrindColors.secondary)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .padding(.top, 8)
                    .buttonStyle(.borderedProminent)
                    .tint(GrindColors.primary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30)
            } else {
                // Batch Toolbar
                HStack(spacing: 10) {
                    Text("\(staleTasks.count) stale idea\(staleTasks.count == 1 ? "" : "s")")
                        .font(.geist(.mono, size: 11.5))
                        .foregroundColor(GrindColors.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(GrindTheme.easeSpring) {
                            store.touchTasks(staleTasks)
                        }
                    }) {
                        Label("Touch All (Keep Fresh)", systemImage: "sparkles")
                            .font(.geist(.medium, size: 11.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GrindColors.hair)
                    .cornerRadius(6)
                    
                    Button(action: {
                        withAnimation(GrindTheme.easeSpring) {
                            for t in staleTasks {
                                t.isArchived = true
                            }
                            try? store.context.save()
                            store.reloadAll()
                        }
                    }) {
                        Label("Archive All", systemImage: "archivebox")
                            .font(.geist(.medium, size: 11.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GrindColors.hair)
                    .cornerRadius(6)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(GrindColors.hair.opacity(0.2))
                
                Divider()
                    .background(GrindColors.hair)
                
                // Stale Task List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(staleTasks) { task in
                            staleRow(for: task)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 580, height: 460)
        .background(GrindColors.bg)
    }
    
    private func staleRow(for task: TodoTask) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.geist(.medium, size: 14))
                        .foregroundColor(GrindColors.primary)
                        .lineLimit(1)
                    
                    Text("\(task.daysUntouched)d untouched")
                        .font(.geist(.mono, size: 10))
                        .foregroundColor(GrindColors.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(GrindColors.hair)
                        .clipShape(Capsule())
                }
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.geist(.regular, size: 11.5))
                        .foregroundColor(GrindColors.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 6) {
                Button(action: {
                    withAnimation(GrindTheme.easeSpring) {
                        store.touchTasks([task])
                    }
                }) {
                    Text("Touch")
                        .font(.geist(.medium, size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(GrindColors.hair)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Reset stale counter & keep in Someday")
                
                Button(action: {
                    withAnimation(GrindTheme.easeSpring) {
                        store.moveTask(task, to: .today)
                    }
                }) {
                    Text("Today")
                        .font(.geist(.medium, size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(GrindColors.hair)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Promote to Today")
                
                Button(action: {
                    withAnimation(GrindTheme.easeSpring) {
                        store.moveTask(task, to: .next)
                    }
                }) {
                    Text("Next")
                        .font(.geist(.medium, size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(GrindColors.hair)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Promote to Next")
                
                Button(action: {
                    withAnimation(GrindTheme.easeSpring) {
                        task.isArchived = true
                        try? store.context.save()
                        store.reloadAll()
                    }
                }) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 10.5))
                        .foregroundColor(GrindColors.secondary)
                        .frame(width: 22, height: 22)
                        .background(GrindColors.hair)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Archive task")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GrindColors.cardSomeday)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(GrindColors.hair, lineWidth: 1)
        )
    }
}

