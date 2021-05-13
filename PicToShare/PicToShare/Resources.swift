import EventKit
import Combine


/// Object centralizing calendar operations.
class CalendarsResource: ObservableObject {
    private let store = EKEventStore()

    /// List of available calendars.
    @Published var calendars: [EKCalendar] = []

    /// Updates the list of available calendars.
    func refreshCalendars() {
        // Requests permission to access the calendar.
        store.requestAccess(to: .event) { [self] granted, error in
            guard granted, error == nil else {
                ErrorManager.error(.calendarsResource,
                        key: "pts.error.resources.calendars.permissions")
                return
            }
            calendars = store.calendars(for: .event)
        }
    }

    /// Asynchronously returns a list of active events in a set of calendars.
    func getCurrentEvents(in calendars: Set<EKCalendar>, _ completion: @escaping ([EKEvent]) -> Void) {
        if calendars.isEmpty {
            completion([])
            return
        }
        // Requests permission to access the calendar.
        store.requestAccess(to: .event) { [self] granted, error in
            guard granted, error == nil else {
                ErrorManager.error(.calendarsResource,
                        key: "pts.error.resources.calendars.permissions")
                completion([])
                return
            }

            // Query for all active events in all calendars.
            let predicate = store.predicateForEvents(withStart: Date(),
                    end: Date(),
                    calendars: calendars.map({ $0 }))

            completion(store.events(matching: predicate))
        }
    }

    /// Saves the given events.
    ///
    /// ATM, it occasionally fails after asking for rights to use the Calendar. Reasons are unknown and the
    /// bug is not repeatable.
    func save(events: [EKEvent]) {
        // Requests permission to access the calendar.
        store.requestAccess(to: .event) { [self] granted, error in
            guard granted, error == nil else {
                ErrorManager.error(.calendarsResource,
                        key: "pts.error.resources.calendars.permissions")
                return
            }

            for event in events {
                do {
                    try store.save(event, span: .thisEvent, commit: false)
                } catch {
                    ErrorManager.error(.calendarsResource,
                            key: "pts.error.resources.calendars.save")
                }
            }
            do {
                try store.commit()
            } catch {
                ErrorManager.error(.calendarsResource,
                        key: "pts.error.resources.calendars.save")
            }
        }
    }
}

extension EKCalendar {
    open override var description: String {
        title
    }
}

extension EKEvent {
    open override var description: String {
        title
    }
}

extension PicToShareError {
    static let calendarsResource =
            PicToShareError(type: "pts.error.resources.calendars")
}
