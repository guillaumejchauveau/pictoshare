//
//  Types.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

// TODO Hashable

/// Object providing a list of keywords to add to imported Documents.
/// The keywords are usually based on information in the current context.
protocol DocumentAnnotator: CustomStringConvertible {
    typealias CompletionHandler = (Result<[String], DocumentAnnotatorError>) -> Void

    func makeAnnotations(_ completion: @escaping CompletionHandler)
}

enum DocumentAnnotatorError: Error {
    case permissionError
}

/// Object attaching the Document file to an external application or content.
protocol DocumentIntegrator: CustomStringConvertible {
    func integrate(documents: [URL])
}


protocol DocumentType: CustomStringConvertible {
    /// A path to the script used to process the Document.
    var documentProcessorScript: URL? { get }
    /// Indicates if a copy of the file should be made before running the script.
    var copyBeforeProcessing: Bool { get }
    /// Indicates if a the original file should be removed if the script creates new files.
    var removeOriginalOnProcessingByproduct: Bool { get }
    /// The Document Annotators used to annotate the Document.
    var documentAnnotators: [DocumentAnnotator] { get }
    /// The Document Integrators that will use the Document.
    var documentIntegrators: [DocumentIntegrator] { get }
    /// The URL of the folder containing links to all Documents of this Type.
    var folder: URL { get }
}

protocol UserContext: CustomStringConvertible {
    /// Additionnal Document Annotators.
    var documentAnnotators: [DocumentAnnotator] { get }
    /// Additionnal Document Integrators.
    var documentIntegrators: [DocumentIntegrator] { get }
}
