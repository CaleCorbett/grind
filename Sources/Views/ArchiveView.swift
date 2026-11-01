import SwiftUI
import SwiftData

public struct ArchiveView: View {
    @ObservedObject private var store = DataStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Logbook")
                        .font(.geist(.bold, size: 18))
                        .foregroundColor(GrindColors.primary)
                    Text("Your completed to-dos, organized by day")
                        .font(.geist(.regular, size: 12))
                        .foregroundColor(GrindColors.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.geist(.semiBold, size: 13))
                .buttonStyle(.borderedProminent)
                .tint(GrindColors.primary)
            }
            .padding(18)
            
            Divider()
                .background(GrindColors.hair)
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GrindColors.secondary)
                TextField("Search archive...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.geist(.regular, size: 14))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(GrindColors.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(GrindColors.hair.opacity(0.4))
            .cornerRadius(8)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            
            // Archived Task List / Grouped Logbook
            if archivedTasks.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundColor(GrindColors.secondary.opacity(0.4))
                    Text("No completed to-dos yet")
                        .font(.geist(.medium, size: 15))
                        .foregroundColor(GrindColors.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(groupedArchivedDays, id: \.day) { group in
                        Section {
                            ForEach(group.tasks) { task in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(GrindColors.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.geist(.medium, size: 14))
                                            .strikethrough(true, color: GrindColors.secondary)
                                            .foregroundColor(GrindColors.secondary)
                                        if let compDate = task.completionDate {
                                            Text(Self.timeOnlyFormatter.string(from: compDate))
                                                .font(.geist(.regular, size: 11))
                                                .foregroundColor(GrindColors.secondary.opacity(0.8))
                                        }
                                    }
                                    Spacer()
                                    Button("Restore") {
                                        task.isArchived = false
                                        task.status = .incomplete
                                        try? store.context.save()
                                        store.refreshTrigger = UUID()
                                    }
                                    .buttonStyle(.plain)
                                    .font(.geist(.medium, size: 12))
                                    .foregroundColor(GrindColors.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(GrindColors.hair)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                                .padding(.vertical, 3)
                            }
                            .onDelete { indices in
                                for i in indices {
                                    store.context.delete(group.tasks[i])
                                }
                                try? store.context.save()
                                store.refreshTrigger = UUID()
                            }
                        } header: {
                            HStack {
                                Text(group.title)
                                    .font(.geist(.semiBold, size: 12.5))
                                    .foregroundColor(GrindColors.primary)
                                Spacer()
                                Text("\(group.tasks.count) completed")
                                    .font(.geist(.mono, size: 11))
                                    .foregroundColor(GrindColors.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 500, height: 480)
        .background(GrindColors.bg)
    }
    
    private struct DayGroup {
        let day: Date
        let title: String
        let tasks: [TodoTask]
    }
    
    private var groupedArchivedDays: [DayGroup] {
        let tasks = archivedTasks
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: tasks) { task -> Date in
            let date = task.completionDate ?? task.creationDate
            return calendar.startOfDay(for: date)
        }
        
        return grouped.keys.sorted(by: >).map { date in
            let title: String
            if calendar.isDateInToday(date) {
                title = "Today"
            } else if calendar.isDateInYesterday(date) {
                title = "Yesterday"
            } else {
                title = Self.dayHeaderFormatter.string(from: date)
            }
            return DayGroup(day: date, title: title, tasks: grouped[date] ?? [])
        }
    }
    
    private static let dayHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private var archivedTasks: [TodoTask] {
        let list = store.archivedTasks
        if searchText.isEmpty {
            return list
        }
        return list.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private static let archiveDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func formatDate(_ date: Date) -> String {
        Self.archiveDateFormatter.string(from: date)
    }
}
