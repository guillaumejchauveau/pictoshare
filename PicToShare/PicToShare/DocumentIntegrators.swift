//
// Created by Guillaume Chauveau on 07/05/2021.
//

import Foundation
import EventKit


struct CurrentEventsDocumentIntegrator: DocumentIntegrator {
    private let store = EKEventStore()

    func integrate(documents: [URL]) throws {
        // You must ask for the user's permission to get Calendar data by adding the
        // "Privacy - Calendar Usage Description" key in info.plist
        store.requestAccess(to: .event) { granted, error in
            guard granted && error == nil else {
                print(String(describing: error))
                return
            }

            let documentsString = documents.map {
                $0.absoluteString
            }.joined(separator: "\n")

            // Create a query that will only select the events occurring now, from all calendars
            let predicate = store.predicateForEvents(withStart: Date(),
                    end: Date(),
                    calendars: nil)

            // Fetch the events matching the predicate
            let events = store.events(matching: predicate)

            for event in events {
                let notes = event.hasNotes
                        ? event.notes! + "\n" + documentsString
                        : documentsString

                event.notes = notes

                try! store.save(event, span: .thisEvent)
            }
        }
    }

    var description = "Événements en cours"
}
