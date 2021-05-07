//
//  ContextAnnotators.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/05/2021.
//
import EventKit

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

/*struct GeoLocalizationContextAnnotator: ContextAnnotator {
    var keywords: [String] = ["geo"]

    var description: String = "Géolocalisation"
}*/
