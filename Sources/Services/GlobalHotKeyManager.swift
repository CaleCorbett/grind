import AppKit
import Carbon
import Combine
import SwiftUI

/// Non-activating HUD panel (Raycast / Hustla style) that accepts keyboard input
/// without pulling the user out of their current full-screen app or space.
private final class FloatingQuickAddNSPanel: NSPanel {
    var onResignKeyCallback: (() -> Void)?
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    override func cancelOperation(_ sender: Any?) {
        onResignKeyCallback?()
    }
    
    override func resignKey() {
        super.resignKey()
        onResignKeyCallback?()
    }
}

public final class GlobalHotKeyManager: ObservableObject {
    public static let shared = GlobalHotKeyManager()
    
    @Published public var shouldOpenQuickAdd: Bool = false
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var floatingPanel: FloatingQuickAddNSPanel?
    private var isDismissingPanel: Bool = false
    
    private init() {
        setupHotKey()
    }
    
    public func setupHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handler: EventHandlerUPP = { (_, _, _) -> OSStatus in
            Task { @MainActor in
                GlobalHotKeyManager.shared.toggleGlobalQuickAdd()
            }
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x47524E44), id: 1) // "GRND"
        // Control + Option + Space
        let modifiers = UInt32(controlKey | optionKey)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    @MainActor
    public func toggleGlobalQuickAdd() {
        if let panel = floatingPanel, panel.isVisible {
            dismissFloatingPanel()
            return
        }
        
        // If Grind's main window is already active and key, use the in-window HUD
        if NSApp.isActive, let keyWin = NSApp.keyWindow, !(keyWin is FloatingQuickAddNSPanel) {
            shouldOpenQuickAdd.toggle()
            return
        }
        
        showFloatingPanel()
    }
    
    @MainActor
    public func showFloatingPanel() {
        let panel: FloatingQuickAddNSPanel
        if let existing = floatingPanel {
            panel = existing
        } else {
            let created = FloatingQuickAddNSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 220),
                styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            created.isFloatingPanel = true
            created.isReleasedWhenClosed = false
            created.level = .floating
            created.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            created.titleVisibility = .hidden
            created.titlebarAppearsTransparent = true
            created.isOpaque = false
            created.backgroundColor = .clear
            created.hasShadow = false
            created.isMovableByWindowBackground = true
            created.onResignKeyCallback = { [weak self] in
                Task { @MainActor in
                    self?.dismissFloatingPanel()
                }
            }
            floatingPanel = created
            panel = created
        }
        
        let binding = Binding<Bool>(
            get: { [weak self] in self?.floatingPanel?.isVisible ?? false },
            set: { [weak self] newValue in
                if !newValue {
                    Task { @MainActor in
                        self?.dismissFloatingPanel()
                    }
                }
            }
        )
        
        let rootView = QuickAddPanel(isPresented: binding, onDismiss: { [weak self] in
            Task { @MainActor in
                self?.dismissFloatingPanel()
            }
        })
        .preferredColorScheme(AppSettings.shared.preferredColorScheme)
        .padding(24)
        
        panel.contentView = NSHostingView(rootView: rootView)
        
        // Center slightly above vertical center on the screen with the mouse cursor
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main
        if let screenFrame = targetScreen?.visibleFrame {
            let panelSize = panel.frame.size
            let x = screenFrame.midX - panelSize.width / 2
            let y = screenFrame.midY - panelSize.height / 2 + (screenFrame.height * 0.12)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }
        
        panel.makeKeyAndOrderFront(nil)
    }
    
    @MainActor
    public func dismissFloatingPanel() {
        guard !isDismissingPanel, let panel = floatingPanel, panel.isVisible else { return }
        isDismissingPanel = true
        panel.orderOut(nil)
        isDismissingPanel = false
    }
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
