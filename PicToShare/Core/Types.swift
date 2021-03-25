//
//  Types.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

protocol ContextAnnotator {
    /// Annotates the given Document.
    ///
    /// - Parameters:
    ///   - document: The Document to annotate.
    // func annotate(document: URL) -> []
}


/// Object defining how to process a Document of a specific Format into a file.
///
/// The exportation and integration process are a work in progress.
protocol DocumentType {
    /// The Exporter used to create the file.
    var contentAnnotatorScript: URL { get }
    /// The Annotators used to process the Document.
    var contextAnnotators: [ContextAnnotator] { get }
}
