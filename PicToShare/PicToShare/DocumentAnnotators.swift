import EventKit
import CoreLocation
import MapKit

struct CurrentCalendarEventsDocumentAnnotator: DocumentAnnotator {
    let description: String = "Événements en cours"

    private let store = EKEventStore()

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        store.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else {
                NotificationManager.notifyUser(
                        "Échec d'annotation avec le calendrier",
                        "PicToShare n'a pas l'autorisation d'accèder au calendrier",
                        "PTS-CalendarAnnotation")
                completion([])
                return
            }

            let predicate = store.predicateForEvents(withStart: Date(),
                    end: Date(),
                    calendars: nil)

            let keywords = store.events(matching: predicate).compactMap {
                $0.title
            }

            completion(keywords)
        }
    }
}

struct GeoLocalizationDocumentAnnotator: DocumentAnnotator {
    private class Delegate: NSObject, CLLocationManagerDelegate {
        var locationRequests: [() -> Void] = []

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            while let request = locationRequests.popLast() {
                request()
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            NotificationManager.notifyUser(
                    "Échec d'annotation avec la géolocalisation",
                    "PicToShare n'a pas l'autorisation d'accèder à l'emplacement",
                    "PTS-GeoLocalizationAnnotation")
        }
    }

    let description: String = "Géolocalisation"

    private let locationManager = CLLocationManager()
    private let delegate = Delegate()

    init() {
        locationManager.delegate = delegate
    }

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        guard CLLocationManager.locationServicesEnabled() else {
            NotificationManager.notifyUser(
                    "Échec d'annotation avec la géolocalisation",
                    "Le service de localisation est désactivé",
                    "PTS-GeoLocalizationAnnotation")
            completion([])
            return
        }
        if locationManager.authorizationStatus == .authorized {
            processLocation(completion)
        } else {
            delegate.locationRequests.append {
                processLocation(completion)
            }
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func processLocation(_ completion: @escaping CompletionHandler) {
        guard let coordinate = locationManager.location?.coordinate else {
            NotificationManager.notifyUser(
                    "Échec d'annotation avec la géolocalisation",
                    "PicToShare n'a pas pu accèder à l'emplacement",
                    "PTS-GeoLocalizationAnnotation")
            completion([])
            return
        }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemark, error in
            let locationAnnotations: [String?] = [
                placemark?.first?.name,
                placemark?.first?.locality,
                placemark?.first?.country
            ]
            completion(locationAnnotations.compactMap({ $0 }))
        }
    }
}
