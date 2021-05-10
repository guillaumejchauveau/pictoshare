import EventKit
import CoreLocation
import MapKit


extension PicToShareError {
    static let currentCalendarEventsDocumentAnnotator =
            PicToShareError(type: "pts.error.annotators.currentCalendarEvents")
}

struct CurrentCalendarEventsDocumentAnnotator: DocumentAnnotator {
    let description = NSLocalizedString("pts.annotators.currentCalendarEvents", comment: "")

    private let store = EKEventStore()

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        store.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else {
                ErrorManager.error(.currentCalendarEventsDocumentAnnotator,
                        key: "pts.error.annotators.permissions")
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

extension PicToShareError {
    static let geoLocalizationDocumentAnnotator =
            PicToShareError(type: "pts.error.annotators.geoLocalization")
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
            ErrorManager.error(.geoLocalizationDocumentAnnotator,
                    key: "pts.error.annotators.geoLocalization.permissions")
        }
    }

    let description = NSLocalizedString("pts.annotators.geoLocalization", comment: "")

    private let locationManager = CLLocationManager()
    private let delegate = Delegate()

    init() {
        locationManager.delegate = delegate
    }

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        guard CLLocationManager.locationServicesEnabled() else {
            ErrorManager.error(.geoLocalizationDocumentAnnotator,
                    key: "pts.error.annotators.geoLocalization.service")
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
            ErrorManager.error(.geoLocalizationDocumentAnnotator,
                    key: "pts.error.annotators.geoLocalization.location")
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
