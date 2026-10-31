import SwiftUI
import AppKit

public struct TaskListCardView: View {
    let listType: TaskListType
    let tasks: [TodoTask]
    let selectedTaskIDs: Set<UUID>
    let expandedTaskID: UUID?
    let isFocusedCard: Bool
    let onSelectTask: (TodoTask, NSEvent.ModifierFlags) -> Void
    let onSelectAllInGroup: (TaskListType) -> Void
    let onDeselectAllInGroup: (TaskListType) -> Void
    let onToggleExpandTask: (TodoTask) -> Void
    let onToggleStatus: (TodoTask) -> Void
    let onEditTask: (TodoTask) -> Void
    let onDeleteTask: (TodoTask) -> Void
    let onMoveTask: (TodoTask, TaskListType) -> Void
    let onBatchSetStatus: ([TodoTask], TaskStatus) -> Void
    let onBatchMove: ([TodoTask], TaskListType) -> Void
    let onBatchDelete: ([TodoTask]) -> Void
    let onAddTask: (String, TaskListType, Date?) -> Void
    let onClearCompleted: (TaskListType) -> Void
    let onToggleFocusCard: (TaskListType) -> Void
    
    @State private var newTodoText: String = ""
    @State private var isTargetedForDrop = false
    @State private var isSelectionModeActive = false
    @FocusState private var isInputFocused: Bool
    
    public init(
        listType: TaskListType,
        tasks: [TodoTask],
        selectedTaskIDs: Set<UUID> = [],
        expandedTaskID: UUID? = nil,
        isFocusedCard: Bool = false,
        onSelectTask: @escaping (TodoTask, NSEvent.ModifierFlags) -> Void = { _, _ in },
        onSelectAllInGroup: @escaping (TaskListType) -> Void = { _ in },
        onDeselectAllInGroup: @escaping (TaskListType) -> Void = { _ in },
        onToggleExpandTask: @escaping (TodoTask) -> Void = { _ in },
        onToggleStatus: @escaping (TodoTask) -> Void,
        onEditTask: @escaping (TodoTask) -> Void,
        onDeleteTask: @escaping (TodoTask) -> Void,
        onMoveTask: @escaping (TodoTask, TaskListType) -> Void,
        onBatchSetStatus: @escaping ([TodoTask], TaskStatus) -> Void = { _, _ in },
        onBatchMove: @escaping ([TodoTask], TaskListType) -> Void = { _, _ in },
        onBatchDelete: @escaping ([TodoTask]) -> Void = { _ in },
        onAddTask: @escaping (String, TaskListType, Date?) -> Void,
        onClearCompleted: @escaping (TaskListType) -> Void,
        onToggleFocusCard: @escaping (TaskListType) -> Void = { _ in }
    ) {
        self.listType = listType
        self.tasks = tasks
        self.selectedTaskIDs = selectedTaskIDs
        self.expandedTaskID = expandedTaskID
        self.isFocusedCard = isFocusedCard
        self.onSelectTask = onSelectTask
        self.onSelectAllInGroup = onSelectAllInGroup
        self.onDeselectAllInGroup = onDeselectAllInGroup
        self.onToggleExpandTask = onToggleExpandTask
        self.onToggleStatus = onToggleStatus
        self.onEditTask = onEditTask
        self.onDeleteTask = onDeleteTask
        self.onMoveTask = onMoveTask
        self.onBatchSetStatus = onBatchSetStatus
        self.onBatchMove = onBatchMove
        self.onBatchDelete = onBatchDelete
        self.onAddTask = onAddTask
        self.onClearCompleted = onClearCompleted
        self.onToggleFocusCard = onToggleFocusCard
    }
    
    private var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    private var completionFraction: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }
    
    private var selectedTasksInCard: [TodoTask] {
        tasks.filter { selectedTaskIDs.contains($0.id) }
    }
    
    private var isAllSelectedInCard: Bool {
        !tasks.isEmpty && selectedTasksInCard.count == tasks.count
    }
    
    private var shouldShowBatchBar: Bool {
        !selectedTasksInCard.isEmpty && (selectedTasksInCard.count > 1 || isAllSelectedInCard || isSelectionModeActive)
    }
    
    private var inlineParsed: ParsedQuickAdd {
        guard !newTodoText.isEmpty else {
            return ParsedQuickAdd(cleanTitle: "", targetList: listType, reminderDate: nil, matchedDateString: nil)
        }
        return QuickAddParser.parse(newTodoText)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            cardHeader
            
            // Per-Group Batch Action Bar (appears when Select All or multi-select is active)
            if shouldShowBatchBar {
                batchActionBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
                .background(GrindColors.hair)
            
            // Task List Content
            if tasks.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(tasks) { task in
                            TaskRowView(
                                task: task,
                                isSelected: selectedTaskIDs.contains(task.id),
                                isExpanded: expandedTaskID == task.id,
                                onSelect: {
                                    let flags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
                                    if !flags.intersection([.command, .shift]).isEmpty {
                                        isSelectionModeActive = true
                                    }
                                    onSelectTask(task, flags)
                                },
                                onToggleExpand: {
                                    withAnimation(GrindTheme.expandSpring) {
                                        onToggleExpandTask(task)
                                    }
                                },
                                onToggle: { onToggleStatus(task) },
                                onOpenSheet: { onEditTask(task) },
                                onDelete: { onDeleteTask(task) },
                                onMove: { target in onMoveTask(task, target) },
                                onReorderBefore: { dragged in
                                    DataStore.shared.reorderTask(dragged, before: task)
                                },
                                onSelectAllInList: {
                                    withAnimation(GrindTheme.snapSpring) {
                                        isSelectionModeActive = true
                                        onSelectAllInGroup(listType)
                                    }
                                },
                                onMarkAllCompleteInList: {
                                    toggleMarkAllCompleteInGroup()
                                }
                            )
                            .draggable(task.id.uuidString)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 2)
                }
            }
            
            Spacer(minLength: 0)
            
            Divider()
                .background(GrindColors.hair)
            
            // Inline Quick-Add Footer
            inlineInputBar
        }
        .padding(20)
        .background(GrindColors.cardBackground(for: listType))
        .clipShape(RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous)
                .stroke(
                    isTargetedForDrop ? GrindColors.primary : GrindColors.cardBorder,
                    lineWidth: isTargetedForDrop ? 2.0 : 1.0
                )
        )
        .scaleEffect(isTargetedForDrop ? 1.014 : 1.0)
        .shadow(
            color: Color.black.opacity(isTargetedForDrop ? 0.16 : 0.06),
            radius: isTargetedForDrop ? 18 : 8,
            x: 0,
            y: isTargetedForDrop ? 8 : 3
        )
        .animation(GrindTheme.snapSpring, value: isTargetedForDrop)
        .animation(GrindTheme.snapSpring, value: shouldShowBatchBar)
        .onChange(of: selectedTasksInCard.isEmpty) { _, isEmpty in
            if isEmpty {
                isSelectionModeActive = false
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let uuid = UUID(uuidString: idString) else { return false }
            if let task = DataStore.shared.task(with: uuid) {
                onMoveTask(task, listType)
                UndoToastManager.shared.showInfo("Moved to \(listType.title)", targetList: listType)
                return true
            }
            return false
        } isTargeted: { targeted in
            isTargetedForDrop = targeted
        }
    }
    
    // MARK: - Card Header with Progress Ring, Select All & Focus Controls
    
    private var cardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(listType.title)
                        .font(.geist(.bold, size: 19))
                        .foregroundColor(GrindColors.primary)
                    
                    // Progress Ring + Monospace Counter Pill (click to Mark All Complete / Reset)
                    let isAllDone = !tasks.isEmpty && completedCount == tasks.count
                    Button(action: {
                        guard !tasks.isEmpty else { return }
                        toggleMarkAllCompleteInGroup()
                    }) {
                        HStack(spacing: 5) {
                            if !tasks.isEmpty {
                                ZStack {
                                    if isAllDone {
                                        Circle()
                                            .fill(GrindColors.primary)
                                            .frame(width: 12, height: 12)
                                            .transition(.scale.combined(with: .opacity))
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(GrindColors.primaryInverted)
                                    } else {
                                        Circle()
                                            .stroke(GrindColors.primary.opacity(0.16), lineWidth: 2)
                                            .frame(width: 11, height: 11)
                                        
                                        Circle()
                                            .trim(from: 0, to: completionFraction)
                                            .stroke(
                                                GrindColors.primary,
                                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 11, height: 11)
                                            .animation(GrindTheme.easeSpring, value: completionFraction)
                                    }
                                }
                                .scaleEffect(isAllDone ? 1.08 : 1.0)
                                .animation(GrindTheme.snapSpring, value: isAllDone)
                            }
                            
                            Text(!tasks.isEmpty ? "\(completedCount)/\(tasks.count)" : "0")
                                .font(.geist(.mono, size: 11.5))
                                .foregroundColor(isAllDone ? GrindColors.primary : GrindColors.secondary)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(GrindColors.hair)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help(isAllDone ? "Reset all in \(listType.title) to To Do" : "Mark all \(tasks.count) in \(listType.title) Complete")
                }
                
                if listType == .today {
                    Text(formattedTodayDate)
                        .font(.geist(.mono, size: 10.5))
                        .foregroundColor(GrindColors.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                } else {
                    Text(listType.subtitle)
                        .font(.geist(.regular, size: 11))
                        .foregroundColor(GrindColors.secondary.opacity(0.85))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Header Action Buttons
            let isAllDoneInCard = !tasks.isEmpty && completedCount == tasks.count
            HStack(spacing: 6) {
                // Mark All Complete / Incomplete in Group Button
                if !tasks.isEmpty {
                    Button(action: {
                        toggleMarkAllCompleteInGroup()
                    }) {
                        Image(systemName: isAllDoneInCard ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isAllDoneInCard ? GrindColors.primaryInverted : GrindColors.secondary)
                            .frame(width: 26, height: 26)
                            .background(isAllDoneInCard ? GrindColors.primary : GrindColors.hair.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(isAllDoneInCard ? "Mark All Incomplete in \(listType.title)" : "Mark All Complete in \(listType.title) (⇧⌘↵)")
                    
                    // Select All / Deselect All in Group Button
                    Button(action: {
                        withAnimation(GrindTheme.snapSpring) {
                            if isAllSelectedInCard {
                                isSelectionModeActive = false
                                onDeselectAllInGroup(listType)
                            } else {
                                isSelectionModeActive = true
                                onSelectAllInGroup(listType)
                            }
                        }
                    }) {
                        Image(systemName: isAllSelectedInCard ? "checklist.checked" : "checklist")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(isAllSelectedInCard ? GrindColors.primaryInverted : GrindColors.secondary)
                            .frame(width: 26, height: 26)
                            .background(isAllSelectedInCard ? GrindColors.primary : GrindColors.hair.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(isAllSelectedInCard ? "Deselect All in \(listType.title)" : "Select All in \(listType.title) (⌘A)")
                }
                
                // Focus Mode Toggle Button (Hustla style)
                Button(action: {
                    onToggleFocusCard(listType)
                }) {
                    Image(systemName: isFocusedCard ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isFocusedCard ? GrindColors.primaryInverted : GrindColors.secondary)
                        .frame(width: 26, height: 26)
                        .background(isFocusedCard ? GrindColors.primary : GrindColors.hair.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isFocusedCard ? "Exit Focus Mode (⌘0)" : "Focus on \(listType.title) (\(listType.shortcutDisplay))")
                
                Button(action: {
                    isInputFocused = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GrindColors.primary)
                        .frame(width: 26, height: 26)
                        .background(GrindColors.hair)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Add to-do to \(listType.title)")
                
                Menu {
                    Button(isAllDoneInCard ? "Mark All Incomplete in \(listType.title)" : "Mark All Complete in \(listType.title) (\(tasks.count - completedCount) left)") {
                        toggleMarkAllCompleteInGroup()
                    }
                    .disabled(tasks.isEmpty)
                    
                    Button(isAllSelectedInCard ? "Deselect All in \(listType.title)" : "Select All in \(listType.title) (\(tasks.count))") {
                        withAnimation(GrindTheme.snapSpring) {
                            if isAllSelectedInCard {
                                isSelectionModeActive = false
                                onDeselectAllInGroup(listType)
                            } else {
                                isSelectionModeActive = true
                                onSelectAllInGroup(listType)
                            }
                        }
                    }
                    .disabled(tasks.isEmpty)
                    
                    Divider()
                    
                    Button(isFocusedCard ? "Show All Cards (⌘0)" : "Focus on \(listType.title) (\(listType.shortcutDisplay))") {
                        onToggleFocusCard(listType)
                    }
                    Divider()
                    Button("Clear Completed (\(completedCount))") {
                        onClearCompleted(listType)
                    }
                    .disabled(completedCount == 0)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GrindColors.secondary)
                        .frame(width: 26, height: 26)
                        .background(GrindColors.hair.opacity(0.5))
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .frame(width: 26, height: 26)
            }
        }
        .padding(.bottom, 14)
    }
    
    private func toggleMarkAllCompleteInGroup() {
        guard !tasks.isEmpty else { return }
        let allDone = completedCount == tasks.count
        let targetStatus: TaskStatus = allDone ? .incomplete : .completed
        onBatchSetStatus(tasks, targetStatus)
        if targetStatus == .completed {
            UndoToastManager.shared.showInfo("Completed all \(tasks.count) in \(listType.title)")
        } else {
            UndoToastManager.shared.showInfo("Reset all \(tasks.count) in \(listType.title)")
        }
    }
    
    // MARK: - Per-Group Batch Action Bar (Linear / Superlist style)
    
    private var batchActionBar: some View {
        let selected = selectedTasksInCard
        let allSelectedCompleted = !selected.isEmpty && selected.allSatisfy { $0.status == .completed }
        
        return HStack(spacing: 6) {
            // Selection count & Select All / Clear toggle
            Button(action: {
                withAnimation(GrindTheme.snapSpring) {
                    if isAllSelectedInCard {
                        isSelectionModeActive = false
                        onDeselectAllInGroup(listType)
                    } else {
                        isSelectionModeActive = true
                        onSelectAllInGroup(listType)
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isAllSelectedInCard ? "checkmark.square.fill" : "minus.square.fill")
                        .font(.system(size: 11))
                    Text("\(selected.count)/\(tasks.count)")
                        .font(.geist(.mono, size: 11))
                }
                .foregroundColor(GrindColors.primary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(GrindColors.hair)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(isAllSelectedInCard ? "Deselect all in \(listType.title)" : "Select all \(tasks.count) in \(listType.title)")
            
            // Mark All Done / Reset
            Button(action: {
                let targetStatus: TaskStatus = allSelectedCompleted ? .incomplete : .completed
                onBatchSetStatus(selected, targetStatus)
            }) {
                HStack(spacing: 3.5) {
                    Image(systemName: allSelectedCompleted ? "arrow.uturn.backward" : "checkmark")
                        .font(.system(size: 9.5, weight: .bold))
                    Text(allSelectedCompleted ? "Reset" : "Done")
                        .font(.geist(.medium, size: 11))
                }
                .foregroundColor(GrindColors.primaryInverted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(GrindColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(allSelectedCompleted ? "Reset selected to To Do" : "Mark selected as Done (Space)")
            
            // Move Selected to other groups
            ForEach(TaskListType.allCases) { target in
                if target != listType {
                    Button(action: {
                        onBatchMove(selected, target)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8, weight: .bold))
                            Text(target.title)
                                .font(.geist(.mono, size: 10.5))
                        }
                        .foregroundColor(GrindColors.primary)
                        .padding(.horizontal, 6.5)
                        .padding(.vertical, 3.5)
                        .background(GrindColors.hair)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .help("Move \(selected.count) selected to \(target.title) (\(target.shortcutNumber))")
                }
            }
            
            Spacer(minLength: 2)
            
            // Delete Selected
            Button(role: .destructive, action: {
                onBatchDelete(selected)
                isSelectionModeActive = false
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background( Color.red.opacity(0.12) )
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Delete \(selected.count) selected (⌘⌫)")
            
            // Clear selection X button
            Button(action: {
                withAnimation(GrindTheme.snapSpring) {
                    isSelectionModeActive = false
                    onDeselectAllInGroup(listType)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(GrindColors.secondary)
                    .frame(width: 22, height: 22)
                    .background(GrindColors.hair)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Clear selection (Esc)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(GrindColors.hair.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(GrindColors.cardBorder, lineWidth: 1)
        )
        .padding(.bottom, 10)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: emptyIconName)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(GrindColors.secondary.opacity(0.45))
            Text(emptyMessage)
                .font(.geist(.regular, size: 13.5))
                .foregroundColor(GrindColors.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { isInputFocused = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Add Item")
                        .font(.geist(.medium, size: 12))
                }
                .foregroundColor(GrindColors.primary.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(GrindColors.hair)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Inline Quick-Add Footer with Live Date Detection
    
    private var inlineInputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isInputFocused ? GrindColors.primary : GrindColors.secondary)
            
            TextField("Add to \(listType.title)...", text: $newTodoText)
                .textFieldStyle(.plain)
                .font(.geist(.regular, size: 14.5))
                .focused($isInputFocused)
                .onSubmit {
                    commitNewTodo()
                }
            
            // Live inline parsed reminder badge (Godspeed / Hustla style)
            if let matchedDate = inlineParsed.matchedDateString, inlineParsed.reminderDate != nil {
                HStack(spacing: 3) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                    Text(matchedDate)
                        .font(.geist(.mono, size: 10.5))
                }
                .foregroundColor(GrindColors.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(GrindColors.hair)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .transition(.scale.combined(with: .opacity))
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
        .padding(.top, 12)
        .padding(.bottom, 2)
        .animation(GrindTheme.snapSpring, value: inlineParsed.reminderDate != nil)
    }
    
    private func commitNewTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let parsed = inlineParsed
        let finalTitle = parsed.cleanTitle.isEmpty ? trimmed : parsed.cleanTitle
        onAddTask(finalTitle, listType, parsed.reminderDate)
        newTodoText = ""
    }
    
    private static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    private var formattedTodayDate: String {
        Self.todayFormatter.string(from: Date())
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
