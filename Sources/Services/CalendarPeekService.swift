import Foundation
import EventKit
import SwiftUI
import Combine

public struct CalendarEventItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarTitle: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendarTitle: String = "Calendar"
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarTitle = calendarTitle
    }
    
    public var isNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    public var formattedTime: String {
        if isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

@MainActor
public final class CalendarPeekService: ObservableObject {
    public static let shared = CalendarPeekService()
    
    @Published public private(set) var todayEvents: [CalendarEventItem] = []
    @Published public private(set) var hasCalendarAccess: Bool = false
    
    private let eventStore = EKEventStore()
    private var refreshTimer: AnyCancellable? = nil
    
    public init() {
        if Bundle.main.bundleURL.pathExtension == "app" {
            startPeriodicRefresh()
        }
    }
    
    public func requestCalendarAccess() async -> Bool {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return false
        }
        
        if #available(macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                hasCalendarAccess = granted
                if granted {
                    reloadEvents()
                }
                return granted
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    Task { @MainActor in
                        self.hasCalendarAccess = granted
                        if granted {
                            self.reloadEvents()
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    public func reloadEvents() {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let rawEvents = eventStore.events(matching: predicate)
        
        let sorted = rawEvents
            .filter { $0.status != .canceled }
            .sorted { $0.startDate < $1.startDate }
            .map { ekEvent in
                CalendarEventItem(
                    id: ekEvent.eventIdentifier ?? UUID().uuidString,
                    title: ekEvent.title ?? "Untitled Event",
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    isAllDay: ekEvent.isAllDay,
                    calendarTitle: ekEvent.calendar?.title ?? "Calendar"
                )
            }
        
        self.todayEvents = sorted
    }
    
    public func setMockEvents(_ events: [CalendarEventItem]) {
        self.todayEvents = events
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.publish(every: 900, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.reloadEvents()
            }
        reloadEvents()
    }
}

