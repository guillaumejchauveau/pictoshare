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
protocol DocumentSource: CustomStringConvertible {
    /// Core constructor for Sources.
    ///
    /// This constructor is required because Sources are instantiated
    /// automatically by the Core, upon loading.
    ///
    /// - Parameters:
    ///   - with: The Configuration object corresponding to this specific
    /// Source's scope.
    ///   - uuid: The identifier of this specific Source.
    init(with: Configuration, uuid: UUID)
    /// The identifier of this specific Source. It is used to differentiate
    /// Source instances consistently on loading.
    var uuid: UUID { get }
    /// Sets the callback function to call when the Source has a Document ready
    /// for importation.
    ///
    /// - Parameter _: A closure taking a Document in argument.
    func setImportCallback(_: @escaping (AnyObject) -> Void)
    /// Asks the Source to provide a Document. The Source will call the import
    /// callback when a Document is available.
    ///
    /// - Parameter with: Overloading Configuration for this importation.
    func promptDocument(with: Configuration)
}

/// Object capable of modifying (annotating) a Document.
///
/// The nature of the modification is specific to the Document Format.
protocol DocumentAnnotator: DocumentFormatCompatible, CustomStringConvertible {
    /// Core constructor for Annotators.
    ///
    /// This constructor is required because Annotators are instantiated
    /// automatically by the Core, upon loading.
    ///
    /// - Parameters:
    ///   - with: The Configuration object corresponding to this specific
    /// Annotator's scope.
    ///   - uuid: The identifier of this specific Annotator.
    init(with: Configuration, uuid: UUID)
    /// The identifier of this specific Annotator. It is used to differentiate
    /// Annotator instances consistently on loading.
    var uuid: UUID { get }
    /// Annotates the given Document.
    ///
    /// - Parameters:
    ///   - document: The Document to annotate.
    ///   - with: Overloading Configuration for this annotation.
    /// - Throws: `CoreError.incompatibleDocumentFormat` when the Document
    ///     cannot be annotate because of its Format.
    func annotate(document: AnyObject, with: Configuration) throws
}


/// The exportation process is still a work in progress.
protocol DocumentExporter: DocumentFormatCompatible, CustomStringConvertible {
    init(with: Configuration, uuid: UUID)
    var uuid: UUID { get }
    func export(document: AnyObject, with: Configuration) throws
}


/// Object defining how to process a Document of a specific Format from a
/// Source into a file.
///
/// The exportation and integration process are a work in progress.
struct DocumentType: CustomStringConvertible {
    let description: String
    /// The identifier of this specific Document Type. It is used to
    /// differentiate Type instances consistently on loading.
    let uuid: UUID
    /// The Format of the Document Type.
    let format: AnyClass
    /// The Annotators used to process the Document.
    private(set) var annotators: [DocumentAnnotator] = []
    /// The Exporter used to create the file.
    private(set) var exporter: DocumentExporter?

    /// Creates a Document Type for a given Format.
    ///
    /// - Parameters:
    ///   - description: Human-readable description of this instance.
    ///   - uuid: The identifier of this specific Type.
    ///   - format: The Format of the Type.
    init(description: String, uuid: UUID, format: AnyClass) {
        self.description = description
        self.uuid = uuid
        self.format = format
    }

    /// Appends an Annotator to the list.
    ///
    /// - Parameter annotator: The Annotator to add.
    /// - Throws: `CoreError.incompatibleDocumentFormat` if the Annotator cannot
    ///     process this Type's Format.
    mutating func append(annotator: DocumentAnnotator) throws {
        guard annotator.isCompatibleWith(format: format) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        annotators.append(annotator)
    }

    /// Removes an Annotator at a given index in the list.
    ///
    /// - Parameter at: The index to remove.
    mutating func removeAnnotator(at index: Int) {
        annotators.remove(at: index)
    }

    /// Inserts an Annotator in the list.
    ///
    /// - Parameters:
    ///   - annotator: The Annotator to insert.
    ///   - i: The index on which the Annotator should be inserted.
    /// - Throws: `CoreError.incompatibleDocumentFormat` if the Annotator cannot
    ///     process this Type's Format.
    mutating func insert(annotator: DocumentAnnotator, at i: Int) throws {
        guard annotator.isCompatibleWith(format: format) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        annotators.insert(annotator, at: i)
    }

    /// Removes all the Annotators of the list.
    mutating func removeAllAnnotators() {
        annotators.removeAll()
    }

    /// Sets this Type's Exporter.
    ///
    /// - Parameter exporter: The Exporter to use.
    /// - Throws: `CoreError.incompatibleDocumentFormat` if the Exporter cannot
    ///     process this Type's Format.
    mutating func set(exporter: DocumentExporter) throws {
        guard exporter.isCompatibleWith(format: format) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        self.exporter = exporter
    }
}
