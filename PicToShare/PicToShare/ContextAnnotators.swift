//
//  ContextAnnotators.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/05/2021.
//

struct CurrentCalendarEventsContextAnnotator: ContextAnnotator {
    var keywords: [String] = ["calendar"]

    var description: String = "Événements en cours"
}

struct GeoLocalizationContextAnnotator: ContextAnnotator {
    var keywords: [String] = ["geo"]

    var description: String = "Géolocalisation"
}
