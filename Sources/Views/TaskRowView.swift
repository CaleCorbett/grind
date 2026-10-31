import SwiftUI

public struct TaskRowView: View {
    let task: TodoTask
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onToggleExpand: () -> Void
    let onToggle: () -> Void
    let onOpenSheet: () -> Void
    let onDelete: () -> Void
    let onMove: (TaskListType) -> Void
    let onReorderBefore: ((TodoTask) -> Void)?
    let onSelectAllInList: (() -> Void)?
    let onMarkAllCompleteInList: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isTargetedForRowDrop = false
    @State private var draftTitle: String = ""
    @State private var draftNotes: String = ""
    @State private var showDatePickerPopover = false
    @FocusState private var focusedField: InlineField?
    
    private enum InlineField {
        case title
        case notes
    }
    
    public init(
        task: TodoTask,
        isSelected: Bool = false,
        isExpanded: Bool = false,
        onSelect: @escaping () -> Void = {},
        onToggleExpand: @escaping () -> Void = {},
        onToggle: @escaping () -> Void,
        onOpenSheet: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onMove: @escaping (TaskListType) -> Void,
        onReorderBefore: ((TodoTask) -> Void)? = nil,
        onSelectAllInList: (() -> Void)? = nil,
        onMarkAllCompleteInList: (() -> Void)? = nil
    ) {
        self.task = task
        self.isSelected = isSelected
        self.isExpanded = isExpanded
        self.onSelect = onSelect
        self.onToggleExpand = onToggleExpand
        self.onToggle = onToggle
        self.onOpenSheet = onOpenSheet
        self.onDelete = onDelete
        self.onMove = onMove
        self.onReorderBefore = onReorderBefore
        self.onSelectAllInList = onSelectAllInList
        self.onMarkAllCompleteInList = onMarkAllCompleteInList
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Row Header
            HStack(alignment: .center, spacing: 13) {
                StatusToggleView(status: task.status, action: onToggle)
                
                if isExpanded {
                    TextField("Task title", text: $draftTitle)
                        .font(.geist(.semiBold, size: 15.5))
                        .foregroundColor(GrindColors.primary)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .title)
                        .onSubmit {
                            commitInlineEdits()
                            onToggleExpand()
                        }
                } else {
                    let isCompleted = (task.status == .completed)
                    // Title with animated left-to-right strikethrough line
                    Text(task.title)
                        .font(.geist(.medium, size: 15.5))
                        .foregroundColor(isCompleted ? GrindColors.secondary : GrindColors.primary)
                        .lineLimit(2)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(GrindColors.secondary)
                                .frame(height: 1.5)
                                .scaleEffect(x: isCompleted ? 1.0 : 0.0, y: 1.0, anchor: .leading)
                                .animation(GrindTheme.easeSpring, value: isCompleted)
                                .allowsHitTesting(false)
                        }
                        .animation(GrindTheme.easeSpring, value: isCompleted)
                }
                
                Spacer(minLength: 6)
                
                // Right-aligned Meta Badges & Hover Quick-Triage Actions
                if !isExpanded {
                    trailingCompactAccessories
                } else {
                    Button(action: {
                        commitInlineEdits()
                        onToggleExpand()
                    }) {
                        KeycapBadge("↵ Done")
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Things 3-style Inline Unfolding Detail Drawer
            if isExpanded {
                expandedDetailContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, isExpanded ? 14 : 12)
        .padding(.vertical, isExpanded ? 14 : 11)
        .background(
            RoundedRectangle(cornerRadius: GrindTheme.rowRadius, style: .continuous)
                .fill(rowBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GrindTheme.rowRadius, style: .continuous)
                .strokeBorder(rowBorderColor, lineWidth: isExpanded || isSelected ? 1.0 : 0)
        )
        .overlay(alignment: .top) {
            if isTargetedForRowDrop {
                Capsule()
                    .fill(GrindColors.primary)
                    .frame(height: 2)
                    .padding(.horizontal, 6)
                    .offset(y: -2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(
            color: Color.black.opacity(isExpanded ? 0.09 : 0.0),
            radius: isExpanded ? 8 : 0,
            x: 0,
            y: isExpanded ? 3 : 0
        )
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first,
                  let uuid = UUID(uuidString: idString),
                  uuid != task.id,
                  let dragged = DataStore.shared.task(with: uuid) else {
                return false
            }
            if let onReorderBefore {
                onReorderBefore(dragged)
            } else {
                DataStore.shared.reorderTask(dragged, before: task)
            }
            return true
        } isTargeted: { targeted in
            withAnimation(GrindTheme.snapSpring) {
                isTargetedForRowDrop = targeted
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            onSelect()
            onToggleExpand()
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                draftTitle = task.title
                draftNotes = task.notes ?? ""
                focusedField = .notes
            } else {
                commitInlineEdits()
            }
        }
        .onAppear {
            draftTitle = task.title
            draftNotes = task.notes ?? ""
        }
        .contextMenu {
            Button(isExpanded ? "Collapse Inline Editor" : "Expand Inline (↵)") {
                onToggleExpand()
            }
            Button("Open Detail Sheet...") {
                onOpenSheet()
            }
            if let onSelectAllInList {
                Button("Select All in \(task.list.title) (⌘A)") {
                    onSelectAllInList()
                }
            }
            if let onMarkAllCompleteInList {
                Button("Mark All Complete in \(task.list.title) (⇧⌘↵)") {
                    onMarkAllCompleteInList()
                }
            }
            
            Divider()
            
            Menu("Move To") {
                ForEach(TaskListType.allCases) { target in
                    if task.list != target {
                        Button("\(target.title) (\(target.shortcutNumber))") {
                            onMove(target)
                        }
                    }
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
    
    // MARK: - Trailing Compact Accessories & Hover Quick-Triage
    
    @ViewBuilder
    private var trailingCompactAccessories: some View {
        HStack(spacing: 6) {
            // Hover Quick-Triage Actions (Linear / Superlist style)
            if isHovered || isSelected {
                let target = task.list.primaryQuickMoveTarget
                Button(action: {
                    onMove(target)
                    UndoToastManager.shared.showInfo("Moved to \(target.title)", targetList: target)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: target == .today ? "arrow.turn.left.up" : "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(target.title)
                            .font(.geist(.mono, size: 10.5))
                    }
                    .foregroundColor(GrindColors.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(GrindColors.hair)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Move to \(target.title) (\(target.shortcutNumber))")
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                
                Button(action: onToggleExpand) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(GrindColors.secondary)
                        .frame(width: 20, height: 20)
                        .background(GrindColors.hair)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Expand notes & details (↵)")
                .transition(.opacity)
            }
            
            // Note indicator badge
            if let notes = task.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: onToggleExpand) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                        .foregroundColor(GrindColors.secondary)
                }
                .buttonStyle(.plain)
                .help("Has notes — click to expand")
            }
            
            // Monospace Reminder Badge
            if let reminder = task.reminderDate {
                HStack(spacing: 3.5) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                    Text(formatTime(reminder))
                        .font(.geist(.mono, size: 11))
                }
                .foregroundColor(isOverdue(reminder) ? .red : GrindColors.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(GrindColors.hair)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
    }
    
    // MARK: - Things 3-Style Inline Expanded Card Content
    
    private var expandedDetailContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .background(GrindColors.hair)
                .padding(.top, 8)
            
            // Inline Notes Field
            TextField("Add notes, links, or sub-steps...", text: $draftNotes, axis: .vertical)
                .font(.geist(.regular, size: 13.5))
                .foregroundColor(GrindColors.primary.opacity(0.9))
                .textFieldStyle(.plain)
                .lineLimit(2...6)
                .focused($focusedField, equals: .notes)
                .onChange(of: draftNotes) { _, newValue in
                    guard isExpanded else { return }
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalized: String? = trimmed.isEmpty ? nil : newValue
                    guard task.notes != normalized else { return }
                    task.notes = normalized
                    try? DataStore.shared.context.save()
                }
            
            // Clickable detected URLs in notes
            if !detectedURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(detectedURLs, id: \.absoluteString) { url in
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 9, weight: .bold))
                                    Text(url.host ?? url.absoluteString)
                                        .font(.geist(.mono, size: 11))
                                        .lineLimit(1)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundColor(GrindColors.primary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(GrindColors.hair)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Quick Controls Bar: Reminder Presets + List Switcher + Actions
            HStack(spacing: 6) {
                // Reminder Pill / Picker
                Menu {
                    Button("Later Today (5:00 PM)") {
                        setQuickReminder(hour: 17, dayOffset: 0)
                    }
                    Button("Tomorrow Morning (9:00 AM)") {
                        setQuickReminder(hour: 9, dayOffset: 1)
                    }
                    Button("Next Monday (9:00 AM)") {
                        setNextMondayReminder()
                    }
                    Divider()
                    Button("Custom Date & Time...") {
                        onOpenSheet()
                    }
                    if task.reminderDate != nil {
                        Divider()
                        Button("Clear Reminder", role: .destructive) {
                            clearReminder()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: task.reminderDate != nil ? "bell.badge.fill" : "bell")
                            .font(.system(size: 10))
                        Text(task.reminderDate.map { formatTime($0) } ?? "Remind")
                            .font(.geist(.mono, size: 11))
                    }
                    .foregroundColor(task.reminderDate != nil ? GrindColors.primary : GrindColors.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(GrindColors.hair)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                // Move List Pills
                ForEach(TaskListType.allCases) { list in
                    if list != task.list {
                        Button(action: {
                            commitInlineEdits()
                            onMove(list)
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8, weight: .bold))
                                Text(list.title)
                                    .font(.geist(.mono, size: 10.5))
                            }
                            .foregroundColor(GrindColors.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(GrindColors.hair.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button(action: onOpenSheet) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11))
                        .foregroundColor(GrindColors.secondary)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help("Open full editor sheet")
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help("Delete task (⌘⌫)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var rowBackgroundColor: Color {
        if isExpanded {
            return GrindColors.hair.opacity(0.75)
        } else if isSelected {
            return GrindColors.hair.opacity(0.62)
        } else if isHovered {
            return GrindColors.hair.opacity(0.42)
        }
        return Color.clear
    }
    
    private var rowBorderColor: Color {
        if isExpanded {
            return GrindColors.primary.opacity(0.22)
        } else if isSelected {
            return GrindColors.primary.opacity(0.18)
        }
        return Color.clear
    }
    
    private func commitInlineEdits() {
        var didChange = false
        let cleanTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanTitle.isEmpty && cleanTitle != task.title {
            task.title = cleanTitle
            didChange = true
        }
        let cleanNotes = draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNotes: String? = cleanNotes.isEmpty ? nil : draftNotes
        if task.notes != normalizedNotes {
            task.notes = normalizedNotes
            didChange = true
        }
        if didChange {
            try? DataStore.shared.context.save()
            DataStore.shared.reloadAll()
        }
    }
    
    private func setQuickReminder(hour: Int, dayOffset: Int) {
        let cal = Calendar.current
        guard let baseDay = cal.date(byAdding: .day, value: dayOffset, to: Date()),
              let target = cal.date(bySettingHour: hour, minute: 0, second: 0, of: baseDay) else { return }
        let finalDate = target > Date() ? target : target.addingTimeInterval(86400)
        task.reminderDate = finalDate
        try? DataStore.shared.context.save()
        ReminderService.shared.scheduleReminder(for: task)
        DataStore.shared.refreshTrigger = UUID()
    }
    
    private func setNextMondayReminder() {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.weekday = 2 // Monday
        comps.hour = 9
        comps.minute = 0
        if let nextMon = cal.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime) {
            task.reminderDate = nextMon
            try? DataStore.shared.context.save()
            ReminderService.shared.scheduleReminder(for: task)
            DataStore.shared.refreshTrigger = UUID()
        }
    }
    
    private func clearReminder() {
        task.reminderDate = nil
        try? DataStore.shared.context.save()
        ReminderService.shared.cancelReminder(for: task)
        DataStore.shared.refreshTrigger = UUID()
    }
    
    private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    
    private var detectedURLs: [URL] {
        guard !draftNotes.isEmpty, let detector = Self.linkDetector else { return [] }
        let matches = detector.matches(in: draftNotes, options: [], range: NSRange(location: 0, length: draftNotes.utf16.count))
        return matches.compactMap { $0.url }
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    private func formatTime(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return Self.timeFormatter.string(from: date)
        } else {
            return Self.dateTimeFormatter.string(from: date)
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        task.status != .completed && date < Date()
    }
}
