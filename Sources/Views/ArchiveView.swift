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
                    Text("Archive")
                        .font(.geist(.bold, size: 18))
                        .foregroundColor(GrindColors.primary)
                    Text("All completed and archived to-dos")
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
            
            // Archived Task List
            if archivedTasks.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundColor(GrindColors.secondary.opacity(0.4))
                    Text("No archived to-dos")
                        .font(.geist(.medium, size: 15))
                        .foregroundColor(GrindColors.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(archivedTasks) { task in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(GrindColors.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.geist(.medium, size: 14))
                                    .strikethrough(true, color: GrindColors.secondary)
                                    .foregroundColor(GrindColors.secondary)
                                if let compDate = task.completionDate {
                                    Text("Completed \(formatDate(compDate))")
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
                            .cornerRadius(6)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { indices in
                        for i in indices {
                            store.context.delete(archivedTasks[i])
                        }
                        try? store.context.save()
                        store.refreshTrigger = UUID()
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 480, height: 460)
        .background(GrindColors.bg)
    }
    
    private var archivedTasks: [TodoTask] {
        _ = store.refreshTrigger
        let descriptor = FetchDescriptor<TodoTask>()
        let all = (try? store.context.fetch(descriptor)) ?? []
        return all
            .filter { $0.isArchived || $0.status == .completed }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { ($0.completionDate ?? Date.distantPast) > ($1.completionDate ?? Date.distantPast) }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
