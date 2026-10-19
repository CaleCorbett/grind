import SwiftUI

public struct TaskRowView: View {
    let task: TodoTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: (TaskListType) -> Void
    
    @State private var isHovered = false
    
    public init(
        task: TodoTask,
        onToggle: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onMove: @escaping (TaskListType) -> Void
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onMove = onMove
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Checkbox
            StatusToggleView(status: task.status, action: onToggle)
            
            // Task Title with Strikethrough
            Text(task.title)
                .font(.geist(.medium, size: 16))
                .foregroundColor(task.status == .completed ? GrindColors.secondary : GrindColors.primary)
                .strikethrough(task.status == .completed, color: GrindColors.secondary)
                .lineLimit(2)
                .animation(.easeInOut(duration: 0.3), value: task.status)
            
            Spacer()
            
            // Meta Badges
            HStack(spacing: 8) {
                // Note badge (sits before reminder icon)
                if let notes = task.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(GrindColors.secondary)
                }
                
                // Reminder badge
                if let reminder = task.reminderDate {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10))
                        Text(formatTime(reminder))
                            .font(.geist(.regular, size: 12))
                    }
                    .foregroundColor(GrindColors.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(GrindColors.hair)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: GrindTheme.rowRadius, style: .continuous)
                .fill(isHovered ? GrindColors.hair.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            onEdit()
        }
        .contextMenu {
            Button("Edit...") { onEdit() }
            
            Divider()
            
            Menu("Move To") {
                if task.list != .today {
                    Button("Today") { onMove(.today) }
                }
                if task.list != .next {
                    Button("Next") { onMove(.next) }
                }
                if task.list != .someday {
                    Button("Someday") { onMove(.someday) }
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: date)
    }
}
