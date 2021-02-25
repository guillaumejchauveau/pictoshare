//
//  Types.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

/**
 * UUID
 */

enum UUIDError: Error {
    case duplicateUUID
}

/**
 * Document Formats
 */

protocol DocumentFormatCompatible {
    var compatibleFormats: [AnyClass] { get }
    func isCompatibleWith(format: AnyClass) -> Bool
}

extension DocumentFormatCompatible {
    func isCompatibleWith(format: AnyClass) -> Bool {
        return self.compatibleFormats.contains(where: { (compatibleFormat: AnyClass) in
            return compatibleFormat == format
        })
    }
}

/**
 * Document Sources
 */

protocol DocumentSource: CustomStringConvertible {
    init(with: Configuration, uuid: UUID)
    var uuid: UUID { get }
    func setImportCallback(_: @escaping (AnyObject) -> Void)
    func promptDocument(with: Configuration)
}

/**
 * Document Annotators
 */

enum DocumentAnnotatorError: Error {
    case imcompatibleDocumentFormat
}

protocol DocumentAnnotator: DocumentFormatCompatible, CustomStringConvertible {
    init(with: Configuration, uuid: UUID)
    var uuid: UUID { get }
    func annotate(document: AnyObject, with: Configuration) throws
}

/**
 * Document Exporters
 */

enum DocumentExporterError: Error {
    case imcompatibleDocumentFormat
}

protocol DocumentExporter: DocumentFormatCompatible, CustomStringConvertible {
    init(with: Configuration)
    func export(document: AnyObject, with: Configuration) throws
}

/**
 * Document Types
 */

enum DocumentTypeError: Error {
    case invalidConfiguration
    case imcompatibleAnnotator
}

class DocumentType: CustomStringConvertible {
    let description: String
    let uuid: UUID

    let format: AnyClass
    let exporter: DocumentExporter
    private var annotators: [DocumentAnnotator] = []

    public init(name: String, uuid: UUID, format: AnyClass, exporter: DocumentExporter) throws {
        self.description = name
        self.uuid = uuid
        guard exporter.isCompatibleWith(format: format) else {
            throw DocumentTypeError.invalidConfiguration
        }
        self.format = format
        self.exporter = exporter
    }

    public func getAnnotators() -> IndexingIterator<Array<DocumentAnnotator>> {
        return self.annotators.makeIterator()
    }

    public func add(annotator: DocumentAnnotator) throws {
        guard annotator.isCompatibleWith(format: self.format) else {
            throw DocumentTypeError.imcompatibleAnnotator
        }
        self.annotators.append(annotator)
    }

    public func removeAnnotator(at index: Int) {
        self.annotators.remove(at: index)
    }
}
