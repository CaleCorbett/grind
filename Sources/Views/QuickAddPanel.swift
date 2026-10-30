import SwiftUI

public struct QuickAddPanel: View {
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil
    
    @State private var inputText: String = ""
    @State private var manualListOverride: TaskListType? = nil
    @FocusState private var isFieldFocused: Bool
    
    public init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.onDismiss = onDismiss
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
                HStack(spacing: 7) {
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(GrindColors.primary)
                    Text("Quick-Add")
                        .font(.geist(.bold, size: 14))
                        .foregroundColor(GrindColors.primary)
                    
                    KeycapBadge("^⌥Space")
                }
                Spacer()
                Button(action: closePanel) {
                    HStack(spacing: 4) {
                        KeycapBadge("Esc")
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GrindColors.secondary)
                            .padding(5)
                            .background(GrindColors.hair)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            
            // Text Input with subtle active card surface tint
            VStack(alignment: .leading, spacing: 8) {
                TextField("e.g. dentist Friday 3pm, call mom tomorrow, read book someday...", text: $inputText)
                    .font(.geist(.medium, size: 16.5))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(GrindColors.cardBackground(for: effectiveList))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(GrindColors.primary.opacity(0.18), lineWidth: 1)
                    )
                    .focused($isFieldFocused)
                    .onKeyPress(.tab) {
                        cycleTargetList()
                        return .handled
                    }
                    .onSubmit {
                        submit()
                    }
                
                // Live Token Highlighting Preview (Godspeed / Hustla style)
                if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   (parsed.matchedDateString != nil || parsed.cleanTitle.lowercased() != inputText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(GrindColors.secondary)
                        
                        Text(parsed.cleanTitle)
                            .font(.geist(.medium, size: 12))
                            .foregroundColor(GrindColors.primary)
                            .lineLimit(1)
                        
                        if let matchedToken = parsed.matchedDateString {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 9))
                                Text(matchedToken)
                                    .font(.geist(.mono, size: 10.5))
                            }
                            .foregroundColor(GrindColors.primaryInverted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GrindColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(GrindTheme.snapSpring, value: parsed.matchedDateString)
            
            // Intelligence / Parsed Chips & Keyboard List Selector (⌘1, ⌘2, ⌘3)
            HStack(spacing: 8) {
                ForEach(TaskListType.allCases) { list in
                    let isSelected = (list == effectiveList)
                    Button(action: {
                        withAnimation(GrindTheme.snapSpring) {
                            manualListOverride = list
                        }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isSelected ? GrindColors.primary : GrindColors.secondary.opacity(0.35))
                                .frame(width: 6, height: 6)
                            Text(list.title)
                                .font(.geist(.semiBold, size: 12))
                            KeycapBadge(list.shortcutDisplay)
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 6)
                        .padding(.vertical, 5)
                        .background(isSelected ? GrindColors.hair : Color.clear)
                        .foregroundColor(isSelected ? GrindColors.primary : GrindColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(isSelected ? GrindColors.primary.opacity(0.35) : GrindColors.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(KeyEquivalent(Character("\(list.shortcutNumber)")), modifiers: .command)
                }
                
                Spacer()
                
                // Parsed Date Chip
                if let reminder = parsed.reminderDate {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 10))
                        Text(formatReminder(reminder))
                            .font(.geist(.mono, size: 11))
                    }
                    .foregroundColor(GrindColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(GrindColors.hair)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Footer Info
            HStack {
                HStack(spacing: 6) {
                    KeycapBadge("↵")
                    Text("Save")
                        .font(.geist(.regular, size: 11))
                        .foregroundColor(GrindColors.secondary)
                    
                    Text("·")
                        .foregroundColor(GrindColors.secondary)
                    
                    KeycapBadge("⌘1–3 / ⇥")
                    Text("Switch List")
                        .font(.geist(.regular, size: 11))
                        .foregroundColor(GrindColors.secondary)
                }
                
                Spacer()
                
                Button(action: submit) {
                    HStack(spacing: 5) {
                        Text("Add to \(effectiveList.title)")
                            .font(.geist(.semiBold, size: 12.5))
                        KeycapBadge("↵", inverted: true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  ? GrindColors.primary.opacity(0.35)
                                  : GrindColors.primary)
                    )
                    .foregroundColor(GrindColors.primaryInverted)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(width: 530)
        .background(
            RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous)
                .fill(GrindColors.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GrindTheme.cardRadius, style: .continuous)
                .stroke(GrindColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.26), radius: 28, x: 0, y: 14)
        .onAppear {
            isFieldFocused = true
        }
    }
    
    private func closePanel() {
        isPresented = false
        onDismiss?()
    }
    
    private func cycleTargetList() {
        let all = TaskListType.allCases
        guard let idx = all.firstIndex(of: effectiveList) else { return }
        let next = all[(idx + 1) % all.count]
        withAnimation(GrindTheme.snapSpring) {
            manualListOverride = next
        }
    }
    
    private func submit() {
        let title = parsed.cleanTitle.isEmpty ? inputText : parsed.cleanTitle
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let target = effectiveList
        DataStore.shared.addTask(
            title: trimmed,
            to: target,
            reminderDate: parsed.reminderDate
        )
        SoundManager.shared.play(.notification)
        UndoToastManager.shared.showInfo("Added to \(target.title) · “\(trimmed)”", targetList: target)
        
        inputText = ""
        manualListOverride = nil
        closePanel()
    }
    
    private static let todayReminderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "'Today', h:mm a"
        return f
    }()
    
    private static let tomorrowReminderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "'Tomorrow', h:mm a"
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
