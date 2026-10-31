import SwiftUI
import SwiftData
import AppKit

public struct MainView: View {
    @ObservedObject private var store = DataStore.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var hotKey = GlobalHotKeyManager.shared
    @ObservedObject private var toastManager = UndoToastManager.shared
    
    @State private var editingTask: TodoTask? = nil
    @State private var isShowingQuickAdd: Bool = false
    @State private var isShowingArchive: Bool = false
    @State private var isShowingSettings: Bool = false
    
    // Focus Mode, Multi-Selection & Keyboard Navigation State
    @State private var focusedList: TaskListType? = nil
    @State private var activeList: TaskListType = .today
    @State private var selectedTaskIDs: Set<UUID> = []
    @State private var lastSelectedTaskID: UUID? = nil
    @State private var expandedTaskID: UUID? = nil
    @State private var keyMonitor: Any? = nil
    
    public init() {}
    
    private var visibleLists: [TaskListType] {
        if let focused = focusedList {
            return [focused]
        }
        return TaskListType.allCases
    }
    
    public var body: some View {
        ZStack {
            // Background
            GrindColors.bg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Header Bar
                headerBar
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 18)
                
                // The 3 Signature Lists (or Single Focused Card)
                GeometryReader { geo in
                    let isSingleFocus = (focusedList != nil)
                    let cardWidth = isSingleFocus
                        ? min(680, max(380, geo.size.width - 64))
                        : max(290, (geo.size.width - 56 - 36) / 3)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 18) {
                            if isSingleFocus {
                                Spacer(minLength: 0)
                            }
                            
                            ForEach(visibleLists) { listType in
                                TaskListCardView(
                                    listType: listType,
                                    tasks: store.tasks(for: listType),
                                    selectedTaskIDs: selectedTaskIDs,
                                    expandedTaskID: expandedTaskID,
                                    isFocusedCard: focusedList == listType,
                                    onSelectTask: { task, flags in
                                        handleTaskSelection(task, flags: flags)
                                    },
                                    onSelectAllInGroup: { group in
                                        selectAll(in: group)
                                    },
                                    onDeselectAllInGroup: { group in
                                        deselectAll(in: group)
                                    },
                                    onToggleExpandTask: { task in
                                        activeList = task.list
                                        selectedTaskIDs = [task.id]
                                        lastSelectedTaskID = task.id
                                        if expandedTaskID == task.id {
                                            expandedTaskID = nil
                                        } else {
                                            expandedTaskID = task.id
                                        }
                                    },
                                    onToggleStatus: { store.toggleTaskStatus($0) },
                                    onEditTask: { editingTask = $0 },
                                    onDeleteTask: { task in
                                        selectedTaskIDs.remove(task.id)
                                        if lastSelectedTaskID == task.id { lastSelectedTaskID = selectedTaskIDs.first }
                                        if expandedTaskID == task.id { expandedTaskID = nil }
                                        store.deleteTask(task)
                                    },
                                    onMoveTask: { task, target in
                                        store.moveTask(task, to: target)
                                    },
                                    onBatchSetStatus: { batch, status in
                                        store.setStatus(status, for: batch)
                                    },
                                    onBatchMove: { batch, target in
                                        store.moveTasks(batch, to: target)
                                        for item in batch {
                                            selectedTaskIDs.remove(item.id)
                                        }
                                        UndoToastManager.shared.showInfo(
                                            "Moved \(batch.count) to \(target.title)",
                                            targetList: target
                                        )
                                    },
                                    onBatchDelete: { batch in
                                        for item in batch {
                                            selectedTaskIDs.remove(item.id)
                                            if expandedTaskID == item.id { expandedTaskID = nil }
                                        }
                                        lastSelectedTaskID = selectedTaskIDs.first
                                        store.deleteTasks(batch)
                                    },
                                    onAddTask: { title, list, reminder in
                                        store.addTask(title: title, to: list, reminderDate: reminder)
                                    },
                                    onClearCompleted: { store.clearCompleted(in: $0) },
                                    onToggleFocusCard: { target in
                                        withAnimation(GrindTheme.easeSpring) {
                                            focusedList = (focusedList == target) ? nil : target
                                            activeList = target
                                        }
                                    }
                                )
                                .frame(width: cardWidth)
                                .frame(maxHeight: .infinity)
                                .transition(.scale(scale: 0.96).combined(with: .opacity))
                            }
                            
                            if isSingleFocus {
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 14)
                        .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                    }
                }
                
                // Subtle Keyboard Command Legend Footer (Godspeed / Linear style)
                keyboardLegendFooter
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
            }
            
            // Floating Quick-Add HUD Overlay
            if isShowingQuickAdd {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { isShowingQuickAdd = false }
                
                QuickAddPanel(isPresented: $isShowingQuickAdd)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
            
            // Floating Undo / Destination Toast
            VStack {
                Spacer()
                ToastView()
            }
        }
        .animation(GrindTheme.easeSpring, value: isShowingQuickAdd)
        .animation(GrindTheme.easeSpring, value: focusedList)
        .sheet(item: $editingTask) { task in
            TaskEditorSheet(task: task)
        }
        .sheet(isPresented: $isShowingArchive) {
            ArchiveView()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .preferredColorScheme(settings.preferredColorScheme)
        .onReceive(hotKey.$shouldOpenQuickAdd) { shouldOpen in
            if shouldOpen {
                withAnimation(GrindTheme.easeSpring) {
                    isShowingQuickAdd = true
                }
                hotKey.shouldOpenQuickAdd = false
            }
        }
        .onReceive(toastManager.$requestedFocusList) { requested in
            if let target = requested {
                withAnimation(GrindTheme.easeSpring) {
                    focusedList = target
                    activeList = target
                }
                toastManager.requestedFocusList = nil
            }
        }
        .onAppear {
            AutoMoveService.shared.performDailySweep()
            installKeyboardNavigationMonitor()
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
        .background(
            Group {
                Button("") { UndoToastManager.shared.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                
                Button("") { isShowingQuickAdd.toggle() }
                    .keyboardShortcut("n", modifiers: .command)
                
                Button("") {
                    withAnimation(GrindTheme.easeSpring) { focusedList = nil }
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Button("") {
                    withAnimation(GrindTheme.easeSpring) {
                        focusedList = (focusedList == .today) ? nil : .today
                        activeList = .today
                    }
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("") {
                    withAnimation(GrindTheme.easeSpring) {
                        focusedList = (focusedList == .next) ? nil : .next
                        activeList = .next
                    }
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("") {
                    withAnimation(GrindTheme.easeSpring) {
                        focusedList = (focusedList == .someday) ? nil : .someday
                        activeList = .someday
                    }
                }
                .keyboardShortcut("3", modifiers: .command)
            }
            .opacity(0)
        )
    }
    
    // MARK: - Selection & Per-Group Select All Helpers
    
    private func handleTaskSelection(_ task: TodoTask, flags: NSEvent.ModifierFlags) {
        activeList = task.list
        
        if flags.contains(.command) {
            if selectedTaskIDs.contains(task.id) {
                selectedTaskIDs.remove(task.id)
            } else {
                selectedTaskIDs.insert(task.id)
                lastSelectedTaskID = task.id
            }
        } else if flags.contains(.shift),
                  let anchorID = lastSelectedTaskID,
                  let anchorTask = store.task(with: anchorID),
                  anchorTask.list == task.list {
            let groupTasks = store.tasks(for: task.list)
            if let startIdx = groupTasks.firstIndex(where: { $0.id == anchorID }),
               let endIdx = groupTasks.firstIndex(where: { $0.id == task.id }) {
                let range = min(startIdx, endIdx)...max(startIdx, endIdx)
                for idx in range {
                    selectedTaskIDs.insert(groupTasks[idx].id)
                }
            }
        } else {
            selectedTaskIDs = [task.id]
            lastSelectedTaskID = task.id
        }
    }
    
    private func selectAll(in group: TaskListType) {
        activeList = group
        let groupTasks = store.tasks(for: group)
        for task in groupTasks {
            selectedTaskIDs.insert(task.id)
        }
        if let first = groupTasks.first {
            lastSelectedTaskID = first.id
        }
    }
    
    private func deselectAll(in group: TaskListType) {
        let groupTasks = store.tasks(for: group)
        for task in groupTasks {
            selectedTaskIDs.remove(task.id)
        }
        if let lastID = lastSelectedTaskID, groupTasks.contains(where: { $0.id == lastID }) {
            lastSelectedTaskID = selectedTaskIDs.first
        }
    }
    
    private func toggleSelectAllInActiveGroup() {
        let targetGroup = focusedList ?? activeList
        let groupTasks = store.tasks(for: targetGroup)
        guard !groupTasks.isEmpty else { return }
        let allSelected = groupTasks.allSatisfy { selectedTaskIDs.contains($0.id) }
        withAnimation(GrindTheme.snapSpring) {
            if allSelected {
                deselectAll(in: targetGroup)
            } else {
                selectAll(in: targetGroup)
            }
        }
    }
    
    private func toggleMarkAllCompleteInActiveGroup() {
        let targetGroup = focusedList ?? activeList
        let groupTasks = store.tasks(for: targetGroup)
        guard !groupTasks.isEmpty else { return }
        let allDone = groupTasks.allSatisfy { $0.status == .completed }
        let targetStatus: TaskStatus = allDone ? .incomplete : .completed
        store.setStatus(targetStatus, for: groupTasks)
        if targetStatus == .completed {
            UndoToastManager.shared.showInfo("Completed all \(groupTasks.count) in \(targetGroup.title)")
        } else {
            UndoToastManager.shared.showInfo("Reset all \(groupTasks.count) in \(targetGroup.title)")
        }
    }
    
    private var selectedTasks: [TodoTask] {
        selectedTaskIDs.compactMap { store.task(with: $0) }
    }
    
    // MARK: - Header Bar with Focus Mode Switcher
    
    private var headerBar: some View {
        HStack(alignment: .center) {
            // App Branding & Title
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(GrindColors.primary)
                        .frame(width: 28, height: 28)
                    Text("G")
                        .font(.geist(.bold, size: 16))
                        .foregroundColor(GrindColors.primaryInverted)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Grind")
                        .font(.geist(.bold, size: 18))
                        .foregroundColor(GrindColors.primary)
                    Text("Focus. Check. Repeat.")
                        .font(.geist(.regular, size: 11))
                        .foregroundColor(GrindColors.secondary)
                }
            }
            
            Spacer()
            
            // Focus Mode Switcher Pill Bar (All / Today ⌘1 / Next ⌘2 / Someday ⌘3)
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation(GrindTheme.easeSpring) {
                        focusedList = nil
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.split.3x1")
                            .font(.system(size: 11, weight: .medium))
                        Text("Board")
                            .font(.geist(.medium, size: 12))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(focusedList == nil ? GrindColors.cardToday : Color.clear)
                    .foregroundColor(focusedList == nil ? GrindColors.primary : GrindColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .shadow(color: Color.black.opacity(focusedList == nil ? 0.06 : 0), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                
                ForEach(TaskListType.allCases) { list in
                    let isFocused = (focusedList == list)
                    Button(action: {
                        withAnimation(GrindTheme.easeSpring) {
                            focusedList = isFocused ? nil : list
                            activeList = list
                        }
                    }) {
                        HStack(spacing: 5) {
                            Text(list.title)
                                .font(.geist(.medium, size: 12))
                            Text("⌘\(list.shortcutNumber)")
                                .font(.geist(.mono, size: 10))
                                .foregroundColor(GrindColors.secondary.opacity(0.8))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(isFocused ? GrindColors.cardToday : Color.clear)
                        .foregroundColor(isFocused ? GrindColors.primary : GrindColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .shadow(color: Color.black.opacity(isFocused ? 0.06 : 0), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(GrindColors.hair)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Spacer()
            
            // Header Action Buttons
            HStack(spacing: 8) {
                // Quick-Add Trigger Button with Monospace Keycap
                Button(action: { isShowingQuickAdd = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Quick-Add")
                            .font(.geist(.semiBold, size: 12.5))
                        KeycapBadge("⌘N", inverted: true)
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                    .padding(.vertical, 6)
                    .background(GrindColors.primary)
                    .foregroundColor(GrindColors.primaryInverted)
                    .clipShape(RoundedRectangle(cornerRadius: GrindTheme.btnRadius, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                
                // Archive Button
                Button(action: { isShowingArchive = true }) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GrindColors.secondary)
                        .frame(width: 32, height: 32)
                        .background(GrindColors.hair)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Archive")
                
                // Settings Button
                Button(action: { isShowingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GrindColors.secondary)
                        .frame(width: 32, height: 32)
                        .background(GrindColors.hair)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Grind Settings (⌘,)")
            }
        }
    }
    
    // MARK: - Keyboard Legend Footer
    
    private var keyboardLegendFooter: some View {
        HStack(spacing: 14) {
            legendItem(key: "↑↓←→", label: "Navigate")
            legendItem(key: "⌘A", label: "Select All")
            legendItem(key: "⇧⌘↵", label: "Complete All in \((focusedList ?? activeList).title)")
            legendItem(key: "Space", label: "Cycle Status")
            legendItem(key: "1·2·3", label: "Move")
            legendItem(key: "^⌥Space", label: "Global Capture")
            Spacer()
            if !selectedTaskIDs.isEmpty {
                Button(action: {
                    withAnimation(GrindTheme.snapSpring) {
                        selectedTaskIDs.removeAll()
                        lastSelectedTaskID = nil
                        expandedTaskID = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        KeycapBadge("Esc")
                        Text("Clear (\(selectedTaskIDs.count))")
                            .font(.geist(.mono, size: 11))
                            .foregroundColor(GrindColors.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(0.85)
    }
    
    private func legendItem(key: String, label: String) -> some View {
        HStack(spacing: 4) {
            KeycapBadge(key)
            Text(label)
                .font(.geist(.regular, size: 11))
                .foregroundColor(GrindColors.secondary)
        }
    }
    
    // MARK: - Local Keyboard Navigation Monitor (Godspeed / Linear style)
    
    private func installKeyboardNavigationMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Ignore when modal overlays are open
            if isShowingQuickAdd || isShowingArchive || isShowingSettings || editingTask != nil {
                return event
            }
            
            // Ignore if user is actively typing in a TextField / NSTextView
            if let responder = event.window?.firstResponder, responder is NSTextView {
                // Allow Escape to exit inline expansion or unfocus text field
                if event.keyCode == 53 { // Escape
                    if expandedTaskID != nil {
                        withAnimation(GrindTheme.expandSpring) {
                            expandedTaskID = nil
                        }
                        event.window?.makeFirstResponder(nil)
                        return nil
                    }
                    event.window?.makeFirstResponder(nil)
                    return nil
                }
                return event
            }
            
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Command + A (keyCode 0) -> Select All / Deselect All in active group
            if flags == .command && event.keyCode == 0 {
                toggleSelectAllInActiveGroup()
                return nil
            }
            
            // Shift + Command + Return (keyCode 36) -> Mark All Complete / Reset in active group
            if flags == [.command, .shift] && event.keyCode == 36 {
                toggleMarkAllCompleteInActiveGroup()
                return nil
            }
            
            // Command + Backspace (keyCode 51) -> Delete selected task(s)
            if flags == .command && event.keyCode == 51 {
                let batch = selectedTasks
                if !batch.isEmpty {
                    selectedTaskIDs.removeAll()
                    lastSelectedTaskID = nil
                    expandedTaskID = nil
                    store.deleteTasks(batch)
                    return nil
                }
            }
            
            // Only handle unmodified keys below
            guard flags.subtracting([.numericPad, .function]).isEmpty else {
                return event
            }
            
            switch event.keyCode {
            case 126, 40: // Up arrow or 'K'
                navigateVertical(direction: -1)
                return nil
            case 125, 38: // Down arrow or 'J'
                navigateVertical(direction: 1)
                return nil
            case 123, 4: // Left arrow or 'H'
                navigateHorizontal(direction: -1)
                return nil
            case 124, 37: // Right arrow or 'L'
                navigateHorizontal(direction: 1)
                return nil
            case 49: // Space -> Cycle status (single) or batch toggle Done/Reset (multi)
                let batch = selectedTasks
                if batch.count == 1, let single = batch.first {
                    store.toggleTaskStatus(single)
                    return nil
                } else if batch.count > 1 {
                    let allDone = batch.allSatisfy { $0.status == .completed }
                    store.setStatus(allDone ? .incomplete : .completed, for: batch)
                    return nil
                }
            case 36: // Return -> Toggle inline expand on primary selected task
                if let id = lastSelectedTaskID ?? selectedTaskIDs.first {
                    withAnimation(GrindTheme.expandSpring) {
                        expandedTaskID = (expandedTaskID == id) ? nil : id
                    }
                    return nil
                }
            case 53: // Escape -> Clear expansion or selection
                if expandedTaskID != nil {
                    withAnimation(GrindTheme.expandSpring) {
                        expandedTaskID = nil
                    }
                    return nil
                } else if !selectedTaskIDs.isEmpty {
                    selectedTaskIDs.removeAll()
                    lastSelectedTaskID = nil
                    return nil
                } else if focusedList != nil {
                    withAnimation(GrindTheme.easeSpring) {
                        focusedList = nil
                    }
                    return nil
                }
            case 18: // "1" -> Move selected task(s) to Today
                if moveSelectedTasks(to: .today) { return nil }
            case 19: // "2" -> Move selected task(s) to Next
                if moveSelectedTasks(to: .next) { return nil }
            case 20: // "3" -> Move selected task(s) to Someday
                if moveSelectedTasks(to: .someday) { return nil }
            default:
                break
            }
            
            return event
        }
    }
    
    private func navigateVertical(direction: Int) {
        let lists = visibleLists
        guard !lists.isEmpty else { return }
        
        if let currentID = lastSelectedTaskID ?? selectedTaskIDs.first,
           let currentTask = store.task(with: currentID) {
            let listTasks = store.tasks(for: currentTask.list)
            if let idx = listTasks.firstIndex(where: { $0.id == currentID }) {
                let nextIdx = idx + direction
                if listTasks.indices.contains(nextIdx) {
                    let target = listTasks[nextIdx]
                    selectedTaskIDs = [target.id]
                    lastSelectedTaskID = target.id
                    activeList = target.list
                }
                return
            }
        }
        
        // Select first available task in visible lists
        for list in lists {
            let listTasks = store.tasks(for: list)
            if let first = listTasks.first {
                selectedTaskIDs = [first.id]
                lastSelectedTaskID = first.id
                activeList = list
                return
            }
        }
    }
    
    private func navigateHorizontal(direction: Int) {
        let lists = visibleLists
        guard lists.count > 1 else { return }
        
        let currentList: TaskListType
        if let currentID = lastSelectedTaskID ?? selectedTaskIDs.first,
           let task = store.task(with: currentID) {
            currentList = task.list
        } else {
            currentList = activeList
        }
        
        guard let listIdx = lists.firstIndex(of: currentList) else { return }
        let targetIdx = (listIdx + direction + lists.count) % lists.count
        let targetList = lists[targetIdx]
        activeList = targetList
        let targetTasks = store.tasks(for: targetList)
        if let first = targetTasks.first {
            selectedTaskIDs = [first.id]
            lastSelectedTaskID = first.id
        } else {
            selectedTaskIDs.removeAll()
            lastSelectedTaskID = nil
        }
    }
    
    private func moveSelectedTasks(to target: TaskListType) -> Bool {
        let batch = selectedTasks
        guard !batch.isEmpty else { return false }
        let movable = batch.filter { $0.list != target }
        guard !movable.isEmpty else { return true }
        store.moveTasks(movable, to: target)
        activeList = target
        let msg = movable.count == 1 ? "Moved to \(target.title)" : "Moved \(movable.count) to \(target.title)"
        UndoToastManager.shared.showInfo(msg, targetList: target)
        return true
    }
}
