import Foundation
import EventKit


struct CurrentEventsDocumentIntegrator: DocumentIntegrator {
    let description = "Ajouter aux événements en cours"

    private let store = EKEventStore()

    /// ATM, it can fail after asking for rights to use the Calendar. Reasons are unknown
    /// It fails and the store.save line
    func integrate(documents: [URL]) {
        // You must ask for the user's permission to get Calendar data by adding the
        // "Privacy - Calendar Usage Description" key in info.plist
        store.requestAccess(to: .event) { granted, error in
            guard granted && error == nil else {
                NotificationManager.notifyUser(
                        "Échec d'intégration au calendrier",
                        "PicToShare n'a pas l'autorisation d'accèder au calendrier",
                        "PTS-CalendarIntegration")
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
                } catch {
                    NotificationManager.notifyUser(
                            "Échec d'intégration au calendrier",
                            "PicToShare n'a pas pu éditer le calendrier pour y intégrer un lien vers le fichier",
                            "PTS-CalendarIntegration")
                }
            }
        }
    }
}
