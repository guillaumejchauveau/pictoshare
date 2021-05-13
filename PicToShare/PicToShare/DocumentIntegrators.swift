// This file contains all the Document Integrator implementations for PicToShare.

import Foundation


/// Current calendar events integrators: adds a link to the documents in the
/// description of all active events at the moment of integration.
struct CurrentCalendarEventsDocumentIntegrator: DocumentIntegrator {
    let description = NSLocalizedString("pts.integrators.currentCalendarEvents", comment: "")

    private let calendarResource: CalendarsResource

    init(_ calendarResource: CalendarsResource) {
        self.calendarResource = calendarResource
    }

    func integrate(documents: [URL], bookmarks: [URL], with configuration: ImportationConfiguration) {
        calendarResource.getCurrentEvents(in: configuration.calendars) { events in
            let documentsString = bookmarks.map {
                $0.absoluteString
            }.joined(separator: "\n")

            for event in events {
                event.notes = event.hasNotes
                        ? event.notes! + "\n" + documentsString
                        : documentsString
            }
            calendarResource.save(events: events)
        }
    }
}
