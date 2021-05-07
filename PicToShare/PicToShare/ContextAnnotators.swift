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
    
    func getKeywords(_ completion: @escaping (Result<[String], ContextAnnotatorError>) -> Void) {
        
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
    let locationManager = CLLocationManager()
    let delegate = Delegate()
    
    class Delegate: NSObject, CLLocationManagerDelegate {}
    
    init() {
        locationManager.delegate = delegate
    }
    
    func getKeywords(_ completion: @escaping (Result<[String], ContextAnnotatorError>) -> Void) {
        
        locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "Annotation") { _ in
            guard let coordinate = locationManager.location?.coordinate else {
                print("Problème de permission")
                completion(.failure(.permissionError))
                return
            }
            
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            location.fetchCityAndCountry { city, country, error in
                guard let city = city, let country = country, error == nil else {
                    print("Problème de localisation")
                    completion(.failure(.locationNotFoundError))
                    return
                }
                
                print(city)
                completion(.success([city, country]))
            }
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
