import SwiftUI

public struct QuickAddPanel: View {
    @Binding var isPresented: Bool
    @State private var inputText: String = ""
    @State private var manualListOverride: TaskListType? = nil
    @FocusState private var isFieldFocused: Bool
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    private var parsed: ParsedQuickAdd {
        QuickAddParser.parse(inputText)
    }
    
    private var effectiveList: TaskListType {
        manualListOverride ?? parsed.targetList
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(GrindColors.primary)
                    Text("Quick-Add To-Do")
                        .font(.geist(.bold, size: 14))
                        .foregroundColor(GrindColors.primary)
                }
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(GrindColors.secondary)
                        .padding(5)
                        .background(GrindColors.hair)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // Text Input
            TextField("e.g. dentist Friday 3pm, call mom tomorrow, read book someday...", text: $inputText)
                .font(.geist(.medium, size: 16))
                .textFieldStyle(.plain)
                .padding(12)
                .background(GrindColors.cardBackground(for: effectiveList))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(GrindColors.cardBorder, lineWidth: 1)
                )
                .focused($isFieldFocused)
                .onSubmit {
                    submit()
                }
            
            // Intelligence / Parsed Chips & List Selector
            HStack(spacing: 8) {
                // List selection pills
                ForEach(TaskListType.allCases) { list in
                    Button(action: {
                        manualListOverride = list
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(list == effectiveList ? GrindColors.primary : GrindColors.secondary.opacity(0.4))
                                .frame(width: 6, height: 6)
                            Text(list.title)
                                .font(.geist(.medium, size: 12))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(list == effectiveList ? GrindColors.hair : Color.clear)
                        .foregroundColor(list == effectiveList ? GrindColors.primary : GrindColors.secondary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(GrindColors.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Parsed Date Chip
                if let reminder = parsed.reminderDate {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 10))
                        Text(formatReminder(reminder))
                            .font(.geist(.regular, size: 12))
                    }
                    .foregroundColor(GrindColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GrindColors.hair)
                    .cornerRadius(6)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Footer Info
            HStack {
                Text("Press ↵ Return to save · Esc to dismiss")
                    .font(.geist(.regular, size: 11))
                    .foregroundColor(GrindColors.secondary)
                Spacer()
                Button("Add To-Do") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .tint(GrindColors.primary)
                .font(.geist(.semiBold, size: 13))
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(width: 500)
        .background(
            RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous)
                .fill(GrindColors.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous)
                .stroke(GrindColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
        .onAppear {
            isFieldFocused = true
        }
    }
    
    private func submit() {
        let title = parsed.cleanTitle.isEmpty ? inputText : parsed.cleanTitle
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        DataStore.shared.addTask(
            title: title,
            to: effectiveList,
            reminderDate: parsed.reminderDate
        )
        SoundManager.shared.play(.notification)
        isPresented = false
        inputText = ""
        manualListOverride = nil
    }
    
    private static let todayReminderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "Today, h:mm a"
        return f
    }()
    
    private static let tomorrowReminderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "Tomorrow, h:mm a"
        return f
    }()
    
    private static let defaultReminderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, h:mm a"
        return f
    }()
    
    private func formatReminder(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Self.todayReminderFormatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return Self.tomorrowReminderFormatter.string(from: date)
        } else {
            return Self.defaultReminderFormatter.string(from: date)
        }
    }
}
