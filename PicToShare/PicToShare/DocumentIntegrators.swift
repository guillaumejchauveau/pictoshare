//
// Created by Guillaume Chauveau on 07/05/2021.
//

import Foundation
import EventKit


struct CurrentEventsDocumentIntegrator: DocumentIntegrator {
    private let store = EKEventStore()

    /// ATM, it can fail after asking for rights to use the Calendar. Reasons are unknown
    /// It fails and the store.save line
    func integrate(documents: [URL]) throws {
        // You must ask for the user's permission to get Calendar data by adding the
        // "Privacy - Calendar Usage Description" key in info.plist
        store.requestAccess(to: .event) { granted, error in
            guard granted && error == nil else {
                print("Calendear Error : \(String(describing: error))")
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

                do {
                    try store.save(event, span: .thisEvent)
                }
                catch {
                    let title = "PTS Echec de synchronisation avec Calendrier"
                    let body = "PicToShare n'a pas pu éditer le calendrier pour y intégrer un lien vers le fichier"
                    NotificationManager.notifyUser(title, body, "PTS-Calendar")
                }
            }
        }
    }

    var description = "Événements en cours"
}
