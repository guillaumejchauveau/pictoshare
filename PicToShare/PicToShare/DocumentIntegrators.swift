// This file contains all the Document Integrator implementations for PicToShare.

import Foundation
import EventKit


/// Current calendar events integrators: adds a link to the documents in the
/// description of all active events at the moment of integration.
struct CurrentCalendarEventsDocumentIntegrator: DocumentIntegrator {
    let description = NSLocalizedString("pts.integrators.currentCalendarEvents", comment: "")

    private let store = EKEventStore()

    /// ATM, it can fail after asking for rights to use the Calendar. Reasons are unknown.
    /// It fails at the store.save line.
    func integrate(documents: [URL]) {
        store.requestAccess(to: .event) { granted, error in
            guard granted && error == nil else {
                ErrorManager.error(.currentCalendarEventsDocumentIntegrator,
                        key: "pts.error.integrators.currentCalendarEvents.permissions")
                return
            }

            let documentsString = documents.map {
                $0.absoluteString
            }.joined(separator: "\n")

            // Created a query that will only select the events occurring now, from all calendars.
            let predicate = store.predicateForEvents(withStart: Date(),
                    end: Date(),
                    calendars: nil)

            // Fetches the events matching the predicate.
            let events = store.events(matching: predicate)

            for event in events {
                let notes = event.hasNotes
                        ? event.notes! + "\n" + documentsString
                        : documentsString

                event.notes = notes

                do {
                    try store.save(event, span: .thisEvent)
                } catch {
                    ErrorManager.error(.currentCalendarEventsDocumentIntegrator,
                            key: "pts.error.integrators.currentCalendarEvents.integrate")
                }
            }
        }
    }
}

extension PicToShareError {
    static let currentCalendarEventsDocumentIntegrator =
            PicToShareError(type: "pts.error.integrators.currentCalendarEvents")
}
