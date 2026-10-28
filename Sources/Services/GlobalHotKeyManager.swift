import AppKit
import Carbon
import Combine

public final class GlobalHotKeyManager: ObservableObject {
    public static let shared = GlobalHotKeyManager()
    
    @Published public var shouldOpenQuickAdd: Bool = false
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    private init() {
        setupHotKey()
    }
    
    public func setupHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handler: EventHandlerUPP = { (_, inEvent, _) -> OSStatus in
            Task { @MainActor in
                NSApp.activate(ignoringOtherApps: true)
                GlobalHotKeyManager.shared.shouldOpenQuickAdd = true
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
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
