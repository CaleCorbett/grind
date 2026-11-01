import Foundation
import AppKit

public struct CapturedContext: Equatable {
    public let appName: String
    public let bundleID: String
    public let title: String
    public let urlString: String
    
    public init(appName: String, bundleID: String, title: String, urlString: String) {
        self.appName = appName
        self.bundleID = bundleID
        self.title = title
        self.urlString = urlString
    }
}

public final class FrontmostAppCaptureService {
    public static let shared = FrontmostAppCaptureService()
    
    public var lastCapturedContext: CapturedContext? = nil
    
    private init() {}
    
    @discardableResult
    public func captureFrontmostContext() -> CapturedContext? {
        let ownBundleID = Bundle.main.bundleIdentifier ?? "com.calecorbett.Grind"
        
        // Find frontmost app other than Grind itself
        guard let frontApp = NSWorkspace.shared.runningApplications.first(where: {
            $0.isActive && $0.bundleIdentifier != ownBundleID
        }) ?? NSWorkspace.shared.frontmostApplication,
        frontApp.bundleIdentifier != ownBundleID,
        let bundleID = frontApp.bundleIdentifier else {
            return nil
        }
        
        let appName = frontApp.localizedName ?? "Browser"
        var scriptSource: String? = nil
        
        switch bundleID.lowercased() {
        case "com.apple.safari":
            scriptSource = """
            tell application "Safari"
                if (count of windows) > 0 and (count of tabs of front window) > 0 then
                    set currentTab to current tab of front window
                    return (name of currentTab) & "|||" & (URL of currentTab)
                end if
            end tell
            """
            
        case "com.google.chrome", "com.brave.browser", "company.thebrowser.browser", "com.microsoft.edgemac":
            let appTarget = (bundleID.lowercased() == "com.google.chrome") ? "Google Chrome" : appName
            scriptSource = """
            tell application "\(appTarget)"
                if (count of windows) > 0 then
                    set currentTab to active tab of front window
                    return (title of currentTab) & "|||" & (URL of currentTab)
                end if
            end tell
            """
            
        case "com.apple.mail":
            scriptSource = """
            tell application "Mail"
                set sel to selection
                if (count of sel) > 0 then
                    set msg to item 1 of sel
                    return (subject of msg) & "|||message://" & (message id of msg)
                end if
            end tell
            """
            
        default:
            return nil
        }
        
        guard let source = scriptSource else { return nil }
        
        var errorDict: NSDictionary? = nil
        if let script = NSAppleScript(source: source),
           let result = script.executeAndReturnError(&errorDict).stringValue {
            let parts = result.components(separatedBy: "|||")
            if parts.count == 2 {
                let title = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let url = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.isEmpty {
                    let captured = CapturedContext(appName: appName, bundleID: bundleID, title: title, urlString: url)
                    self.lastCapturedContext = captured
                    return captured
                }
            }
        }
        
        return nil
    }
}

