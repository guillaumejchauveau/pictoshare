// This file contains all the Document Integrator implementations for PicToShare.

import SwiftUI
import EventKit


/// Current calendar events integrators: adds a link to the documents in the
/// description of all active events at the moment of integration.
struct CurrentCalendarEventsDocumentIntegrator: DocumentIntegrator {
    let description = NSLocalizedString("pts.integrators.currentCalendarEvents", comment: "")

    private let calendarResource: CalendarsResource

    /// Modal view for confirming which events should be edited with a link to the imported Document.
    private struct ConfirmationModalContentView: View {
        let calendarResource: CalendarsResource

        /// Link string.
        let documentsString: String
        @State var availableEvents: [EKEvent]
        @State var selectedEvents: Set<EKEvent>

        var body: some View {
            VStack {
                Text("pts.integrators.currentCalendarEvents.confirmation")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                GroupBox {
                    ScrollView {
                        HStack {
                            SetOptionsView(options: $availableEvents, selected: $selectedEvents)
                            Spacer()
                        }
                    }
                }
                HStack {
                    Button("cancel") {
                        ModalManager.popQueueHead()
                    }.keyboardShortcut(.cancelAction)
                    Button("confirm") {
                        for event in selectedEvents {
                            event.notes = event.hasNotes
                                    ? event.notes! + "\n" + documentsString
                                    : documentsString
                        }
                        calendarResource.save(events: selectedEvents.map({ $0 }))
                        ModalManager.popQueueHead()
                    }.keyboardShortcut(.defaultAction)
                }
            }.frame(width: 250)
        }
    }

    init(_ calendarResource: CalendarsResource) {
        self.calendarResource = calendarResource
    }

    func integrate(
            documents: [URL],
            bookmarks: [URL],
            with configuration: ImportationConfiguration) {
        calendarResource.getCurrentEvents(in: configuration.calendars) { events in
            if events.isEmpty {
                return
            }
            let documentsString = bookmarks.map {
                $0.absoluteString
            }.joined(separator: "\n")

            DispatchQueue.main.async {
                /// Asks confirmation to the user.
                ModalManager.queue(
                        ConfirmationModalContentView(calendarResource: calendarResource,
                                documentsString: documentsString,
                                availableEvents: events,
                                selectedEvents: Set<EKEvent>(events)))
                }
        }
    }
}
