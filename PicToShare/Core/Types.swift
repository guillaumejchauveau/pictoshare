//
//  Types.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation


enum DocumentFormatError: Error {
    /// The given Document or *document processor* (Annotator, Exporter,
    /// ...) is not compatible with a certain format range.
    /// Refer to the throwing method for more information.
    case incompatibleDocumentFormat
}

/// An object capable of providing a list of compatible Document Formats.
protocol DocumentFormatCompatible {
    /// A list of the types of compatible Formats.
    var compatibleFormats: [AnyClass] { get }
    /// Helper function to determine if the object in compatible with a given
    /// Format.
    ///
    /// - Parameter format: The Format to test the compatibility against
    /// - Returns: The result of the test
    func isCompatibleWith(format: AnyClass) -> Bool
}

extension DocumentFormatCompatible {
    /// Helper function to determine if the object in compatible with a given
    /// Format.
    ///
    /// - Parameter format: The Format to test the compatibility against
    /// - Returns: The result of the test
    ///
    /// - Complexity: O(n)
    func isCompatibleWith(format: AnyClass) -> Bool {
        compatibleFormats.contains(where: { compatibleFormat in
            compatibleFormat == format
        })
    }
}

/// Object capable of providing Documents, when asked to or spontaneously.
protocol DocumentSource {
    /// Core constructor for Sources.
    ///
    /// This constructor is required because Sources are instantiated
    /// automatically by the Core, upon loading.
    ///
    /// - Parameters:
    ///   - with: The Configuration object corresponding to this specific
    /// Source's scope.
    init(with: Configuration) throws
    /// Sets the callback function to call when the Source has a Document ready
    /// for importation.
    ///
    /// - Parameter _: A closure taking a Document in argument.
    func setImportCallback(_: @escaping (AnyObject) -> Void)
    /// Asks the Source to provide a Document. The Source will call the import
    /// callback when a Document is available.
    func promptDocument()
}

/// Object capable of modifying (annotating) a Document.
///
/// The nature of the modification is specific to the Document Format.
protocol DocumentAnnotator: DocumentFormatCompatible {
    /// Core constructor for Annotators.
    ///
    /// This constructor is required because Annotators are instantiated
    /// automatically by the Core, upon loading.
    ///
    /// - Parameters:
    ///   - with: The Configuration object corresponding to this specific
    /// Annotator's scope.
    init(with: Configuration) throws
    /// Annotates the given Document.
    ///
    /// - Parameters:
    ///   - document: The Document to annotate.
    /// - Throws: `CoreError.incompatibleDocumentFormat` when the Document
    ///     cannot be annotate because of its Format.
    func annotate(document: AnyObject) throws
}

/// The exportation process is still a work in progress.
protocol DocumentExporter: DocumentFormatCompatible {
    init(with: Configuration) throws
    func export(document: AnyObject) throws
}

/// Object defining how to process a Document of a specific Format into a file.
///
/// The exportation and integration process are a work in progress.
protocol DocumentType {
    /// The Format of the Document Type.
    var format: AnyClass { get }
    /// The Annotators used to process the Document.
    var annotators: [DocumentAnnotator] { get }
    /// The Exporter used to create the file.
    var exporter: DocumentExporter { get }
}
