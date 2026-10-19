import SwiftUI
import SwiftData

public struct MainView: View {
    @ObservedObject private var store = DataStore.shared
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var editingTask: TodoTask? = nil
    @State private var isShowingQuickAdd: Bool = false
    @State private var isShowingArchive: Bool = false
    @State private var isShowingSettings: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background
            GrindColors.bg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Header Bar
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 14)
                
                // The 3 Signature Lists: Today, Next, Someday
                GeometryReader { geo in
                    let cardWidth = max(280, (geo.size.width - 48 - 32) / 3)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            // 1. Today Card
                            TaskListCardView(
                                listType: .today,
                                tasks: store.tasks(for: .today),
                                onToggleStatus: { store.toggleTaskStatus($0) },
                                onEditTask: { editingTask = $0 },
                                onDeleteTask: { store.deleteTask($0) },
                                onMoveTask: { task, target in store.moveTask(task, to: target) },
                                onAddTask: { title, list in store.addTask(title: title, to: list) },
                                onClearCompleted: { store.clearCompleted(in: $0) }
                            )
                            .frame(width: cardWidth)
                            .frame(maxHeight: .infinity)
                            
                            // 2. Next Card
                            TaskListCardView(
                                listType: .next,
                                tasks: store.tasks(for: .next),
                                onToggleStatus: { store.toggleTaskStatus($0) },
                                onEditTask: { editingTask = $0 },
                                onDeleteTask: { store.deleteTask($0) },
                                onMoveTask: { task, target in store.moveTask(task, to: target) },
                                onAddTask: { title, list in store.addTask(title: title, to: list) },
                                onClearCompleted: { store.clearCompleted(in: $0) }
                            )
                            .frame(width: cardWidth)
                            .frame(maxHeight: .infinity)
                            
                            // 3. Someday Card
                            TaskListCardView(
                                listType: .someday,
                                tasks: store.tasks(for: .someday),
                                onToggleStatus: { store.toggleTaskStatus($0) },
                                onEditTask: { editingTask = $0 },
                                onDeleteTask: { store.deleteTask($0) },
                                onMoveTask: { task, target in store.moveTask(task, to: target) },
                                onAddTask: { title, list in store.addTask(title: title, to: list) },
                                onClearCompleted: { store.clearCompleted(in: $0) }
                            )
                            .frame(width: cardWidth)
                            .frame(maxHeight: .infinity)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                    }
                }
            }
            
            // Floating Quick-Add HUD Overlay
            if isShowingQuickAdd {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { isShowingQuickAdd = false }
                
                QuickAddPanel(isPresented: $isShowingQuickAdd)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
            
            // Floating Delete Undo Toast
            VStack {
                Spacer()
                ToastView()
            }
        }
        .animation(GrindTheme.easeSpring, value: isShowingQuickAdd)
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
        .onAppear {
            AutoMoveService.shared.performDailySweep()
        }
        .background(
            // Global app shortcuts
            Button("") {
                UndoToastManager.shared.undo()
            }
            .keyboardShortcut("z", modifiers: .command)
            .opacity(0)
        )
    }
    
    private var headerBar: some View {
        HStack(alignment: .center) {
            // App Branding & Title
            HStack(spacing: 10) {
                // Grind Logo
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
            
            // Header Action Buttons
            HStack(spacing: 8) {
                // Quick-Add Trigger Button
                Button(action: { isShowingQuickAdd = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("New To-Do")
                            .font(.geist(.semiBold, size: 13))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
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
                .help("Grind Settings")
            }
        }
    }
}
