//
//  Core.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation


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

typealias Configuration = Dictionary<String, String>

protocol DocumentSource: CustomStringConvertible {
    init(with: Configuration)
    var importCallback: ((AnyObject) -> Void)? { get set }
    func promptForDocument(with: Configuration)
}


enum DocumentAnnotatorError: Error {
    case imcompatibleDocumentFormat
}

protocol DocumentAnnotator: DocumentFormatCompatible, CustomStringConvertible {
    init(with: Configuration)
    func annotate(document: AnyObject, with: Configuration) throws
}


enum DocumentExporterError: Error {
    case imcompatibleDocumentFormat
}

protocol DocumentExporter: DocumentFormatCompatible, CustomStringConvertible {
    init(with: Configuration)
    func export(document: AnyObject, with: Configuration) throws
}

enum DocumentTypeError: Error {
    case invalidConfiguration
    case imcompatibleAnnotator
}

class DocumentType: CustomStringConvertible {
    let description: String

    private let format: AnyClass
    private let exporter: DocumentExporter
    private var annotators: [DocumentAnnotator] = []

    public init(name: String, format: AnyClass, exporter: DocumentExporter) throws {
        self.description = name
        guard exporter.isCompatibleWith(format: format) else {
            throw DocumentTypeError.invalidConfiguration
        }
        self.format = format
        self.exporter = exporter
    }

    public func getAnnotators() -> IndexingIterator<Array<DocumentAnnotator>> {
        return self.annotators.makeIterator()
    }

    public func getExporter() -> DocumentExporter {
        return self.exporter
    }

    public func add(annotator: DocumentAnnotator) throws {
        guard annotator.isCompatibleWith(format: self.format) else {
            throw DocumentTypeError.imcompatibleAnnotator
        }
        self.annotators.append(annotator)
    }

    public func remove(annotatorAt index: Int) {
        self.annotators.remove(at: index)
    }
}

protocol Library: CustomStringConvertible {
    var id: String { get }
    var formats: [(String, AnyClass)]? { get }
    var sources: [(String, DocumentSource.Type)]? { get }
    var annotators: [(String, DocumentAnnotator.Type)]? { get }
    var exporters: [(String, DocumentExporter.Type)]? { get }
}

enum LibraryManagerError: Error {
    case duplicate(id: String)
}

class LibraryManager {
    private var formats: Dictionary<String, AnyClass> = [:]
    private var sourceTypes: Dictionary<String, DocumentSource.Type> = [:]
    private var annotatorTypes: Dictionary<String, DocumentAnnotator.Type> = [:]
    private var exporterTypes: Dictionary<String, DocumentExporter.Type> = [:]

    func load(library: Library) throws {
        try! library.formats?.forEach({(id: String, format: AnyClass) in
            let key = "\(library.id).formats.\(id)"
            guard !self.formats.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.formats[key] = format
        })
        try! library.sources?.forEach({(id: String, sourceType: DocumentSource.Type) in
            let key = "\(library.id).sources.\(id)"
            guard !self.sourceTypes.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.sourceTypes[key] = sourceType
        })
        try! library.annotators?.forEach({(id: String, annotatorType: DocumentAnnotator.Type) in
            let key = "\(library.id).annotators.\(id)"
            guard !self.annotatorTypes.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.annotatorTypes[key] = annotatorType
        })
        try! library.exporters?.forEach({(id: String, exporterType: DocumentExporter.Type) in
            let key = "\(library.id).exporters.\(id)"
            guard !self.exporterTypes.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.exporterTypes[key] = exporterType
        })
    }

    func get(format key: String) -> AnyClass {
        return self.formats[key]!
    }

    func get(source key: String, with config: Configuration) -> DocumentSource {
        return self.sourceTypes[key]!.init(with: config)
    }

    func get(annotator key: String, with config: Configuration) -> DocumentAnnotator {
        return self.annotatorTypes[key]!.init(with: config)
    }

    func get(exporter key: String, with config: Configuration) -> DocumentExporter {
        return self.exporterTypes[key]!.init(with: config)
    }
}

class ImportationManager {
    private var sources: Dictionary<String, DocumentSource> = [:]
    private var types: Dictionary<String, DocumentType> = [:]



    public func importDocument(with source: DocumentSource) {
        source.promptForDocument(with: [:])
    }

    public func importDocument(_ document: AnyObject) {

    }
}

