import SwiftUI

public struct TaskEditorSheet: View {
    @Bindable var task: TodoTask
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedList: TaskListType = .today
    @State private var selectedStatus: TaskStatus = .incomplete
    @State private var hasReminder: Bool = false
    @State private var reminderDate: Date = Date().addingTimeInterval(3600)
    
    public init(task: TodoTask) {
        self.task = task
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("Edit To-Do")
                    .font(.geist(.bold, size: 16))
                    .foregroundColor(GrindColors.primary)
                Spacer()
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
                .font(.geist(.semiBold, size: 14))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(GrindColors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            Divider()
                .background(GrindColors.hair)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TITLE")
                            .font(.geist(.medium, size: 11))
                            .foregroundColor(GrindColors.secondary)
                            .tracking(0.5)
                        
                        TextField("Task title", text: $title)
                            .font(.geist(.medium, size: 16))
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(GrindColors.hair.opacity(0.4))
                            .cornerRadius(8)
                    }
                    
                    // List Placement
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LIST")
                            .font(.geist(.medium, size: 11))
                            .foregroundColor(GrindColors.secondary)
                            .tracking(0.5)
                        
                        Picker("List", selection: $selectedList) {
                            ForEach(TaskListType.allCases) { list in
                                Text(list.title).tag(list)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Status
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STATUS")
                            .font(.geist(.medium, size: 11))
                            .foregroundColor(GrindColors.secondary)
                            .tracking(0.5)
                        
                        Picker("Status", selection: $selectedStatus) {
                            Text("To Do").tag(TaskStatus.incomplete)
                            if AppSettings.shared.allowInProgress {
                                Text("In Progress").tag(TaskStatus.inProgress)
                            }
                            Text("Done").tag(TaskStatus.completed)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Reminder
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasReminder) {
                            Text("Reminder")
                                .font(.geist(.medium, size: 14))
                                .foregroundColor(GrindColors.primary)
                        }
                        .toggleStyle(.switch)
                        
                        if hasReminder {
                            DatePicker(
                                "Remind at",
                                selection: $reminderDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .padding(8)
                            .background(GrindColors.hair.opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    .padding(12)
                    .background(GrindColors.hair.opacity(0.2))
                    .cornerRadius(10)
                    
                    // Notes Editor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTES & LINKS")
                            .font(.geist(.medium, size: 11))
                            .foregroundColor(GrindColors.secondary)
                            .tracking(0.5)
                        
                        TextEditor(text: $notes)
                            .font(.geist(.regular, size: 14))
                            .frame(minHeight: 100)
                            .padding(6)
                            .background(GrindColors.hair.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    // Delete Button
                    Button(role: .destructive) {
                        DataStore.shared.deleteTask(task)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete To-Do")
                        }
                        .foregroundColor(.red)
                        .font(.geist(.medium, size: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 520)
        .background(GrindColors.bg)
        .onAppear {
            title = task.title
            notes = task.notes ?? ""
            selectedList = task.list
            selectedStatus = task.status
            if let date = task.reminderDate {
                hasReminder = true
                reminderDate = date
            }
        }
    }
    
    private func saveChanges() {
        let oldReminder = task.reminderDate
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        task.list = selectedList
        task.status = selectedStatus
        let newReminder = hasReminder ? reminderDate : nil
        task.reminderDate = newReminder
        
        if oldReminder != newReminder {
            if let newDate = newReminder, newDate > Date() {
                ReminderService.shared.scheduleReminder(for: task)
            } else {
                ReminderService.shared.cancelReminder(for: task)
            }
        }
        
        try? DataStore.shared.context.save()
        DataStore.shared.refreshTrigger = UUID()
    }
}
