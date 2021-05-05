//
//  Types.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

/// Object providing a list of keywords to add to imported Documents.
/// The keywords are usually based on information in the current context.
protocol ContextAnnotator: CustomStringConvertible {
    var keywords: [String] { get }
}


/// Object defining how to process a Document with two components: the Content Annotator, and Context
/// Annotators.
/// The first component is the URL of an AppleScript, that will process the input file into the output file at the
/// proper destination. The Context Annotators will then add Spotlight metadata to the output file.
/// The implementation of the integration of the output file to external applications is not yet planned.
protocol DocumentType: CustomStringConvertible {
    /// The Exporter used to create the file.
    var contentAnnotatorScript: URL? { get }
    /// The Annotators used to process the Document.
    var contextAnnotators: [ContextAnnotator] { get }
    /// The URL of the folder containing links to all Documents of this Type.
    var folder: URL { get }
}
