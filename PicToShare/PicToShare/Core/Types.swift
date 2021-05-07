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
    func makeAnnotations(_ completion: @escaping (Result<[String], ContextAnnotatorError>) -> Void)
}

enum ContextAnnotatorError: Error {
    case permissionError
    case locationNotFoundError
}

/// Object attaching the Document file to an external application or content.
protocol DocumentIntegrator: CustomStringConvertible {
    func integrate(documents: [URL]) throws
}


/// Object defining how to process a Document with two components: the Content Annotator, and Context
/// Annotators.
/// The first component is the URL of an AppleScript, that will process the input file into the output file at the
/// proper destination. The Context Annotators will then add Spotlight metadata to the output file.
/// The implementation of the integration of the output file to external applications is not yet planned.
protocol DocumentType: CustomStringConvertible {
    /// The script used to process the file.
    var contentAnnotatorScript: URL? { get }
    /// Indicates if a copy of the file should be made before running the script.
    var copyBeforeScript: Bool { get }
    /// The ContextAnnotators used to annotate the Document.
    var contextAnnotators: [ContextAnnotator] { get }
    /// The DocumentIntegrators that will use the Document.
    var documentIntegrators: [DocumentIntegrator] { get }
    /// The URL of the folder containing links to all Documents of this Type.
    var folder: URL { get }
}
