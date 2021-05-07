//
//  ContextAnnotators.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/05/2021.
//
import EventKit
import CoreLocation
import MapKit

struct CurrentCalendarEventsContextAnnotator: ContextAnnotator {
    let store = EKEventStore()
    var description: String = "Événements en cours"
    
    func makeAnnotations(_ completion: @escaping (Result<[String], ContextAnnotatorError>) -> Void) {
        
        store.requestAccess(to: .event) { granted, error in
            guard granted && error == nil else {
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

struct GeoLocalizationContextAnnotator: ContextAnnotator {
    var description: String = "Géolocalisation"
    private let locationManager = CLLocationManager()
    private let delegate = Delegate()
    
    init() {
        //locationManager.requestWhenInUseAuthorization()
        locationManager.startMonitoringVisits()
        locationManager.delegate = delegate
    }
    
    class Delegate : NSObject, CLLocationManagerDelegate {}
    
    func makeAnnotations(_ completion: @escaping (Result<[String], ContextAnnotatorError>) -> Void) {
        
        guard let coordinate = locationManager.location?.coordinate else {
            completion(.failure(.permissionError))
            return
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        location.fetchCityAndCountry { city, country, error in
            guard let city = city, let country = country, error == nil else {
                completion(.failure(.locationNotFoundError))
                return
            }
            completion(.success([city, country]))
        }
    }

}

extension CLLocation{
    func fetchCityAndCountry(_ completion: @escaping (_ city: String?, _ country: String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) {
            completion($0?.first?.locality, $0?.first?.country, $1)
        }
    }
}
