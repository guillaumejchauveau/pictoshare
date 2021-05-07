//
//  ContextAnnotators.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/05/2021.
//

import EventKit
import CoreLocation
import MapKit

struct CurrentCalendarEventsDocumentAnnotator: DocumentAnnotator {
    let description: String = "Événements en cours"

    private let store = EKEventStore()
    
    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        store.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else {
                completion(.failure(.permissionError))
                return
            }
            
            let predicate = store.predicateForEvents(withStart: Date(),
                                                     end: Date(),
                                                     calendars: nil)
            
            let keywords = store.events(matching: predicate).compactMap {
                $0.title
            }
            
            completion(.success(keywords))
        }
    }
}

struct GeoLocalizationDocumentAnnotator: DocumentAnnotator {
    private class Delegate : NSObject, CLLocationManagerDelegate {}

    let description: String = "Géolocalisation"

    private let locationManager = CLLocationManager()
    private let delegate = Delegate()
    
    init() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startMonitoringVisits()
        }
        locationManager.delegate = delegate
    }

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        guard let coordinate = locationManager.location?.coordinate else {
            completion(.failure(.permissionError))
            return
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            let locationAnnotations: [String?] = [
                placemarks?.first?.name,
                placemarks?.first?.locality,
                placemarks?.first?.country
            ]
            completion(.success(locationAnnotations.compactMap({$0})))
        }
    }
}
