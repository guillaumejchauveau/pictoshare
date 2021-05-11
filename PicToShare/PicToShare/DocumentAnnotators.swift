// This file contains all the Document Annotator implementations for PicToShare.

import EventKit
import CoreLocation
import MapKit


/// Current calendar events annotator: adds the title of all active events at
/// the moment of annotation.
struct CurrentCalendarEventsDocumentAnnotator: DocumentAnnotator {
    let description = NSLocalizedString("pts.annotators.currentCalendarEvents", comment: "")

    private let store = EKEventStore()

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        // Requests permission to access the calendar.
        store.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else {
                ErrorManager.error(.currentCalendarEventsDocumentAnnotator,
                        key: "pts.error.annotators.currentCalendarEvents.permissions")
                completion([])
                return
            }

            // Query for all active events in all calendars.
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
    static let currentCalendarEventsDocumentAnnotator =
            PicToShareError(type: "pts.error.annotators.currentCalendarEvents")
}

/// Geo localization annotator: adds the country, city, and place names of the
/// current location.
struct GeoLocalizationDocumentAnnotator: DocumentAnnotator {
    /// Internal delegate for the Location Manager. Permission requests go throw
    /// this delegate instead of a callback. In order to return the data to the
    /// correct Importation in the Core, this delegate stores the Annotator
    /// completion callback in an array (via the processLocation function).
    /// It can store more than one request in the eventuality that a new
    /// annotation process starts before the first permission request is
    /// complete.
    private class Delegate: NSObject, CLLocationManagerDelegate {
        var permissionRequests: [() -> Void] = []

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            while let request = permissionRequests.popLast() {
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
            // If not authorized now, ask for permission and then process the
            // location.
            delegate.permissionRequests.append {
                processLocation(completion)
            }
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Use the location stored in the Location Manager and the Geocoder to
    /// retrieve names of interest.
    ///
    /// - Parameter completion: The makeAnnotations completion handler
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

extension PicToShareError {
    static let geoLocalizationDocumentAnnotator =
            PicToShareError(type: "pts.error.annotators.geoLocalization")
}
