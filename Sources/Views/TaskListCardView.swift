import SwiftUI

public struct TaskListCardView: View {
    let listType: TaskListType
    let tasks: [TodoTask]
    let onToggleStatus: (TodoTask) -> Void
    let onEditTask: (TodoTask) -> Void
    let onDeleteTask: (TodoTask) -> Void
    let onMoveTask: (TodoTask, TaskListType) -> Void
    let onAddTask: (String, TaskListType) -> Void
    let onClearCompleted: (TaskListType) -> Void
    
    @State private var newTodoText: String = ""
    @State private var isTargetedForDrop = false
    @FocusState private var isInputFocused: Bool
    
    public init(
        listType: TaskListType,
        tasks: [TodoTask],
        onToggleStatus: @escaping (TodoTask) -> Void,
        onEditTask: @escaping (TodoTask) -> Void,
        onDeleteTask: @escaping (TodoTask) -> Void,
        onMoveTask: @escaping (TodoTask, TaskListType) -> Void,
        onAddTask: @escaping (String, TaskListType) -> Void,
        onClearCompleted: @escaping (TaskListType) -> Void
    ) {
        self.listType = listType
        self.tasks = tasks
        self.onToggleStatus = onToggleStatus
        self.onEditTask = onEditTask
        self.onDeleteTask = onDeleteTask
        self.onMoveTask = onMoveTask
        self.onAddTask = onAddTask
        self.onClearCompleted = onClearCompleted
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            cardHeader
            
            Divider()
                .background(GrindColors.hair)
            
            // Task List Content
            if tasks.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(tasks) { task in
                            TaskRowView(
                                task: task,
                                onToggle: { onToggleStatus(task) },
                                onEdit: { onEditTask(task) },
                                onDelete: { onDeleteTask(task) },
                                onMove: { target in onMoveTask(task, target) }
                            )
                            .draggable(task.id.uuidString)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Spacer(minLength: 0)
            
            Divider()
                .background(GrindColors.hair)
            
            // Inline Quick-Add Footer
            inlineInputBar
        }
        .padding(16)
        .background(GrindColors.cardBackground(for: listType))
        .clipShape(RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous)
                .stroke(isTargetedForDrop ? GrindColors.primary : GrindColors.cardBorder, lineWidth: isTargetedForDrop ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .dropDestination(for: String.self) { items, location in
            guard let idString = items.first, let uuid = UUID(uuidString: idString) else { return false }
            if let task = DataStore.shared.tasks(for: .today, includeArchived: true).first(where: { $0.id == uuid }) ??
                          DataStore.shared.tasks(for: .next, includeArchived: true).first(where: { $0.id == uuid }) ??
                          DataStore.shared.tasks(for: .someday, includeArchived: true).first(where: { $0.id == uuid }) {
                onMoveTask(task, listType)
                return true
            }
            return false
        } isTargeted: { targeted in
            isTargetedForDrop = targeted
        }
    }
    
    private var cardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(listType.title)
                        .font(.geist(.bold, size: 19))
                        .foregroundColor(GrindColors.primary)
                    
                    Text("\(tasks.count)")
                        .font(.geist(.medium, size: 13))
                        .foregroundColor(GrindColors.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(GrindColors.hair)
                        .clipShape(Capsule())
                }
                
                if listType == .today {
                    Text(formattedTodayDate)
                        .font(.geist(.regular, size: 11))
                        .foregroundColor(GrindColors.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            
            Spacer()
            
            // Header Action Buttons
            HStack(spacing: 6) {
                Button(action: {
                    isInputFocused = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(GrindColors.primary)
                        .frame(width: 28, height: 28)
                        .background(GrindColors.hair)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Add to-do to \(listType.title)")
                
                Menu {
                    Button("Clear Completed") {
                        onClearCompleted(listType)
                    }
                    Divider()
                    Button("Focus on This List") {}
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(GrindColors.secondary)
                        .frame(width: 28, height: 28)
                        .background(GrindColors.hair.opacity(0.5))
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28, height: 28)
            }
        }
        .padding(.bottom, 12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: emptyIconName)
                .font(.system(size: 28))
                .foregroundColor(GrindColors.secondary.opacity(0.4))
            Text(emptyMessage)
                .font(.geist(.regular, size: 14))
                .foregroundColor(GrindColors.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var inlineInputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(GrindColors.secondary)
            
            TextField("Add a to-do...", text: $newTodoText)
                .textFieldStyle(.plain)
                .font(.geist(.regular, size: 15))
                .focused($isInputFocused)
                .onSubmit {
                    commitNewTodo()
                }
            
            if !newTodoText.isEmpty {
                Button(action: commitNewTodo) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(GrindColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
    }
    
    private func commitNewTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddTask(trimmed, listType)
        newTodoText = ""
    }
    
    private var formattedTodayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var emptyIconName: String {
        switch listType {
        case .today: return "sun.max"
        case .next: return "calendar.badge.clock"
        case .someday: return "sparkles"
        }
    }
    
    private var emptyMessage: String {
        switch listType {
        case .today: return "Clear for today.\nAdd what needs doing."
        case .next: return "No upcoming tasks.\nReady for the next sprint."
        case .someday: return "No someday ideas yet.\nJot down big dreams."
        }
    }
}
