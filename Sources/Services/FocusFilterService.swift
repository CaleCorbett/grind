import Foundation
import Combine

@MainActor
public final class FocusFilterService: ObservableObject {
    public static let shared = FocusFilterService()
    
    @Published public private(set) var activeFilterListName: String? = nil
    @Published public private(set) var hideSomedayActive: Bool = false
    @Published public private(set) var isFocusFilterActive: Bool = false
    
    public init() {}
    
    public func applyFocusFilter(focusedList: String?, hideSomeday: Bool) {
        self.activeFilterListName = focusedList?.lowercased()
        self.hideSomedayActive = hideSomeday
        self.isFocusFilterActive = true
    }
    
    public func clearFocusFilter() {
        self.activeFilterListName = nil
        self.hideSomedayActive = false
        self.isFocusFilterActive = false
    }
}

