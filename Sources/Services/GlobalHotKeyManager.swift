import AppKit
import Combine

public final class GlobalHotKeyManager: ObservableObject {
    public static let shared = GlobalHotKeyManager()
    
    @Published public var shouldOpenQuickAdd: Bool = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    private init() {
        setupMonitors()
    }
    
    public func setupMonitors() {
        // Monitor for Control + Option + Space
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .option]) && event.keyCode == 49 { // 49 is Space
                self?.shouldOpenQuickAdd = true
                return nil
            }
            return event
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .option]) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    self?.shouldOpenQuickAdd = true
                }
            }
        }
    }
    
    deinit {
        if let gm = globalMonitor { NSEvent.removeMonitor(gm) }
        if let lm = localMonitor { NSEvent.removeMonitor(lm) }
    }
}
