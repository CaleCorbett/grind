import AppKit
import Combine
import Foundation
import SwiftData
import SwiftUI

@main
struct SmokeTestRunner {
    static var failures: [String] = []
    static var passedCount = 0

    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        if condition() {
            passedCount += 1
            print("  ✅ PASS: \(message)")
        } else {
            failures.append(message)
            print("  ❌ FAIL: \(message)")
        }
    }

    @MainActor
    static func pumpRunLoop(seconds: TimeInterval = 0.05) {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.005))
        }
    }

    @MainActor
    static func main() {
        print("====================================================")
        print("🧪 GRIND AUTOMATED SMOKE TEST SUITE")
        print("====================================================")

        // Disable audio playback during automated tests
        let settings = AppSettings.shared
        let origSound = settings.soundEffectsEnabled
        let origAllowInProgress = settings.allowInProgress
        let origArchiveImm = settings.archiveImmediately
        let origMoveBottom = settings.moveCompletedToBottom
        let origSmartQuickAdd = settings.smartQuickAddEnabled
        let origAutoMove = settings.autoMoveRemindersToToday
        let origBadge = settings.menuBarBadge
        let origMode = settings.appearanceMode
        settings.soundEffectsEnabled = false

        // ----------------------------------------------------
        // TEST 1: AppSettings Idempotency & KVO Loop Prevention
        // ----------------------------------------------------
        print("\n[1/7] Testing AppSettings Idempotency & KVO Loop Prevention...")
        var settingsEmissions = 0
        let settingsSub = settings.objectWillChange.sink { _ in
            settingsEmissions += 1
        }

        let curShow = settings.showInMenuBar
        let curAllow = settings.allowInProgress
        let curPos = settings.addTaskPosition
        let curMove = settings.moveCompletedToBottom
        let curSmart = settings.smartQuickAddEnabled
        let curBadge = settings.menuBarBadge
        let curMode = settings.appearanceMode
        let curIcon = settings.selectedAppIcon
        let curArch = settings.archiveImmediately
        let curAuto = settings.autoMoveRemindersToToday

        for _ in 0..<20 {
            settings.showInMenuBar = curShow
            settings.allowInProgress = curAllow
            settings.addTaskPosition = curPos
            settings.moveCompletedToBottom = curMove
            settings.smartQuickAddEnabled = curSmart
            settings.menuBarBadge = curBadge
            settings.appearanceMode = curMode
            settings.selectedAppIcon = curIcon
            settings.archiveImmediately = curArch
            settings.autoMoveRemindersToToday = curAuto
        }
        check(settingsEmissions == 0, "Re-assigning identical values 20x to all AppSettings properties emits 0 objectWillChange events (got \(settingsEmissions))")

        settings.showInMenuBar.toggle()
        settings.showInMenuBar.toggle()
        check(settingsEmissions == 2, "Toggling showInMenuBar twice emits exactly 2 objectWillChange events (got \(settingsEmissions))")
        _ = settingsSub

        // ----------------------------------------------------
        // TEST 2: DataStore Coalesced Emissions, CRUD, Batch & Undo
        // ----------------------------------------------------
        print("\n[2/7] Testing DataStore Coalesced Notifications, CRUD, Reorder, Batch & Undo...")
        let store = DataStore.shared
        // Clear initial starter tasks for clean deterministic assertions
        let allInitial = store.todayTasks + store.nextTasks + store.somedayTasks + store.archivedTasks
        for t in allInitial {
            store.context.delete(t)
        }
        try? store.context.save()
        store.reloadAll()

        var storeEmissions = 0
        let storeSub = store.objectWillChange.sink { _ in
            storeEmissions += 1
        }

        store.addTask(title: "Single emission test", to: .today)
        check(storeEmissions == 1, "DataStore.addTask emits exactly 1 coalesced objectWillChange event (got \(storeEmissions))")
        _ = storeSub

        // Stress insert 45 tasks across Today, Next, Someday
        for i in 1...15 {
            store.addTask(title: "Today Task \(i)", to: .today, notes: "Note \(i)")
            store.addTask(title: "Next Task \(i)", to: .next)
            store.addTask(title: "Someday Task \(i)", to: .someday)
        }
        check(store.todayTasks.count == 16, "Today has 16 tasks after bulk insert (got \(store.todayTasks.count))")
        check(store.nextTasks.count == 15, "Next has 15 tasks after bulk insert (got \(store.nextTasks.count))")
        check(store.somedayTasks.count == 15, "Someday has 15 tasks after bulk insert (got \(store.somedayTasks.count))")

        // 3-state status cycle test
        settings.allowInProgress = true
        settings.archiveImmediately = false
        let sampleTask = store.todayTasks[0]
        check(sampleTask.status == .incomplete, "Initial status is .incomplete")
        store.toggleTaskStatus(sampleTask)
        check(sampleTask.status == .inProgress, "First toggle with allowInProgress=true -> .inProgress")
        store.toggleTaskStatus(sampleTask)
        check(sampleTask.status == .completed, "Second toggle -> .completed")
        check(store.todayRemainingCount == 15 && store.todayTotalCount == 16, "todayRemainingCount (15) and todayTotalCount (16) updated accurately")
        store.toggleTaskStatus(sampleTask)
        check(sampleTask.status == .incomplete, "Third toggle -> .incomplete")

        // Reorder within list and across lists
        let firstToday = store.todayTasks[0]
        let thirdToday = store.todayTasks[2]
        store.reorderTask(thirdToday, before: firstToday)
        check(store.todayTasks.first?.id == thirdToday.id, "Within-list reorderTask places dragged task before target")

        let firstNext = store.nextTasks[0]
        store.reorderTask(firstNext, before: firstToday)
        check(firstNext.list == .today, "Cross-list reorderTask moves task from Next to Today")
        check(store.nextTasks.count == 14 && store.todayTasks.count == 17, "Cross-list reorderTask updates counts on both lists")

        // Batch Mark All Complete & Mark Incomplete
        store.setStatus(.completed, for: store.nextTasks)
        check(store.nextTasks.allSatisfy { $0.status == .completed }, "Batch setStatus(.completed) marks all Next tasks completed")
        store.setStatus(.incomplete, for: store.nextTasks)
        check(store.nextTasks.allSatisfy { $0.status == .incomplete }, "Batch setStatus(.incomplete) marks all Next tasks incomplete")

        // Batch Move
        let somedaySlice = Array(store.somedayTasks.prefix(5))
        store.moveTasks(somedaySlice, to: .next)
        check(store.somedayTasks.count == 10 && store.nextTasks.count == 19, "Batch moveTasks moves 5 tasks from Someday to Next")

        // Batch Delete + Multi-Task Undo
        let toDelete = Array(store.somedayTasks.prefix(4))
        let deletedIDs = Set(toDelete.map(\.id))
        store.deleteTasks(toDelete)
        check(store.somedayTasks.count == 6, "Batch deleteTasks removes 4 tasks from Someday (got \(store.somedayTasks.count))")
        check(UndoToastManager.shared.canUndo, "UndoToastManager.canUndo is true after batch deletion")
        UndoToastManager.shared.undo()
        check(store.somedayTasks.count == 10, "UndoToastManager.undo() restores all 4 deleted tasks to Someday (got \(store.somedayTasks.count))")
        let restoredIDs = Set(store.somedayTasks.map(\.id)).intersection(deletedIDs)
        check(restoredIDs.count == 4, "All 4 restored task UUIDs match original deleted tasks")

        // Clear Completed & Archive verification
        store.setStatus(.completed, for: Array(store.todayTasks.prefix(3)))
        store.clearCompleted(in: .today)
        check(store.todayTasks.count == 14, "clearCompleted archives 3 completed tasks from Today")
        check(store.archivedTasks.count >= 3, "archivedTasks contains archived tasks (got \(store.archivedTasks.count))")

        // ----------------------------------------------------
        // TEST 3: QuickAddParser Edge Cases & Performance Guard
        // ----------------------------------------------------
        print("\n[3/7] Testing QuickAddParser Natural Language & Large Input Guard...")
        settings.smartQuickAddEnabled = true

        let emptyParsed = QuickAddParser.parse("")
        check(emptyParsed.cleanTitle.isEmpty, "Empty input parses to empty cleanTitle")

        let somedayParsed = QuickAddParser.parse("Learn Rust someday")
        check(somedayParsed.targetList == .someday && somedayParsed.cleanTitle == "Learn Rust", "'Learn Rust someday' routes to .someday with clean title 'Learn Rust' (got '\(somedayParsed.cleanTitle)')")

        let datedParsed = QuickAddParser.parse("Dentist appointment tomorrow 3pm")
        check(datedParsed.reminderDate != nil && datedParsed.targetList == .next, "'Dentist appointment tomorrow 3pm' extracts reminderDate and routes to .next")

        let hugeInput = String(repeating: "very long task description word ", count: 500) + "someday"
        let startHuge = CFAbsoluteTimeGetCurrent()
        let hugeParsed = QuickAddParser.parse(hugeInput)
        let elapsedHugeMs = (CFAbsoluteTimeGetCurrent() - startHuge) * 1000.0
        check(elapsedHugeMs < 25.0 && !hugeParsed.cleanTitle.isEmpty, "16,000-char QuickAddParser input completes in \(String(format: "%.2f", elapsedHugeMs))ms (< 25ms) without hanging NSDataDetector")

        // ----------------------------------------------------
        // TEST 4: AutoMoveService Daily Sweep
        // ----------------------------------------------------
        print("\n[4/7] Testing AutoMoveService Daily Sweep...")
        settings.autoMoveRemindersToToday = true
        let pastDueDate = Date().addingTimeInterval(-7200)
        store.addTask(title: "Overdue on Next", to: .next, reminderDate: pastDueDate)
        let beforeTodayCount = store.todayTasks.count
        AutoMoveService.shared.performDailySweep()
        check(store.todayTasks.count == beforeTodayCount + 1, "AutoMoveService moves overdue task from Next to Today and reloads DataStore")

        // ----------------------------------------------------
        // TEST 5: SwiftUI NSHostingView Rendering & RunLoop Settle Check
        // ----------------------------------------------------
        print("\n[5/7] Testing SwiftUI View Rendering & RunLoop Settle (Zero Spin)...")
        FontManager.shared.registerCustomFonts()

        let mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 680),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        mainWindow.isReleasedWhenClosed = false
        let mainHost = NSHostingView(rootView: MainView().modelContainer(store.container))
        mainWindow.contentView = mainHost
        mainHost.layoutSubtreeIfNeeded()

        let menuBarHost = NSHostingView(rootView: MenuBarTodayView().modelContainer(store.container))
        menuBarHost.frame = NSRect(x: 0, y: 0, width: 320, height: 390)
        menuBarHost.layoutSubtreeIfNeeded()

        let quickAddHost = NSHostingView(rootView: QuickAddPanel(isPresented: .constant(true)))
        quickAddHost.frame = NSRect(x: 0, y: 0, width: 520, height: 220)
        quickAddHost.layoutSubtreeIfNeeded()

        let archiveHost = NSHostingView(rootView: ArchiveView().modelContainer(store.container))
        archiveHost.frame = NSRect(x: 0, y: 0, width: 480, height: 460)
        archiveHost.layoutSubtreeIfNeeded()

        let settingsHost = NSHostingView(rootView: SettingsView())
        settingsHost.frame = NSRect(x: 0, y: 0, width: 500, height: 420)
        settingsHost.layoutSubtreeIfNeeded()

        if let editableTask = store.todayTasks.first {
            let editorHost = NSHostingView(rootView: TaskEditorSheet(task: editableTask))
            editorHost.frame = NSRect(x: 0, y: 0, width: 440, height: 520)
            editorHost.layoutSubtreeIfNeeded()
        }

        // Let initial layout settle
        pumpRunLoop(seconds: 0.15)

        // Monitor objectWillChange during idle RunLoop ticks to verify zero feedback loops
        var idleStoreEvents = 0
        var idleSettingsEvents = 0
        let idleSub1 = store.objectWillChange.sink { _ in idleStoreEvents += 1 }
        let idleSub2 = settings.objectWillChange.sink { _ in idleSettingsEvents += 1 }

        pumpRunLoop(seconds: 0.25)

        check(idleStoreEvents == 0, "Zero DataStore invalidations during idle RunLoop with all views hosted (got \(idleStoreEvents))")
        check(idleSettingsEvents == 0, "Zero AppSettings invalidations during idle RunLoop with all views hosted (got \(idleSettingsEvents))")

        // ----------------------------------------------------
        // TEST 6: Live Mutations While Views Are Hosted in NSWindow
        // ----------------------------------------------------
        print("\n[6/7] Testing Live State Mutations Under Hosted Views (No Cascade Loops)...")
        // Mutate tasks and settings while MainView, MenuBarTodayView, SettingsView, ArchiveView are actively observing
        for i in 0..<5 {
            if let t = store.todayTasks.first {
                store.toggleTaskStatus(t)
            }
            settings.menuBarBadge = (i % 2 == 0) ? "total" : "remaining"
            UndoToastManager.shared.requestedFocusList = TaskListType.allCases[i % 3]
            pumpRunLoop(seconds: 0.03)
        }
        UndoToastManager.shared.requestedFocusList = nil
        pumpRunLoop(seconds: 0.08)

        // Now reset counters and verify complete silence after mutations settle
        idleStoreEvents = 0
        idleSettingsEvents = 0
        pumpRunLoop(seconds: 0.20)
        check(idleStoreEvents == 0, "Zero post-mutation DataStore feedback loops while views are mounted (got \(idleStoreEvents))")
        check(idleSettingsEvents == 0, "Zero post-mutation AppSettings feedback loops while views are mounted (got \(idleSettingsEvents))")

        _ = (idleSub1, idleSub2, mainWindow, mainHost, menuBarHost, quickAddHost, archiveHost, settingsHost)

        // ----------------------------------------------------
        // TEST 7: GlobalHotKeyManager FloatingQuickAddNSPanel Lifecycle
        // ----------------------------------------------------
        print("\n[7/7] Testing GlobalHotKeyManager FloatingQuickAddNSPanel Show/Dismiss Cycles...")
        for _ in 0..<5 {
            GlobalHotKeyManager.shared.showFloatingPanel()
            pumpRunLoop(seconds: 0.02)
            GlobalHotKeyManager.shared.dismissFloatingPanel()
            pumpRunLoop(seconds: 0.02)
        }
        check(GlobalHotKeyManager.shared.shouldOpenQuickAdd == false, "5 rapid show/dismiss cycles on FloatingQuickAddNSPanel complete cleanly without re-entrant crash or zombie panel")

        // Restore original user settings
        settings.soundEffectsEnabled = origSound
        settings.allowInProgress = origAllowInProgress
        settings.archiveImmediately = origArchiveImm
        settings.moveCompletedToBottom = origMoveBottom
        settings.smartQuickAddEnabled = origSmartQuickAdd
        settings.autoMoveRemindersToToday = origAutoMove
        settings.menuBarBadge = origBadge
        settings.appearanceMode = origMode

        print("\n====================================================")
        if failures.isEmpty {
            print("🎉 ALL \(passedCount) SMOKE TESTS PASSED!")
            print("====================================================")
            exit(0)
        } else {
            print("💥 \(failures.count) SMOKE TEST(S) FAILED:")
            for f in failures {
                print("   - \(f)")
            }
            print("====================================================")
            exit(1)
        }
    }
}
