//
//  Library.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation


protocol Library: CustomStringConvertible {
    var id: String { get }
    var formats: Dictionary<String, AnyClass> { get }
    var sources: Dictionary<String, DocumentSource.Type> { get }
    var annotators: Dictionary<String, DocumentAnnotator.Type> { get }
    var exporters: Dictionary<String, DocumentExporter.Type> { get }
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
        try! library.formats.forEach({(id: String, format: AnyClass) in
            let key = "\(library.id).formats.\(id)"
            guard !self.formats.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.formats[key] = format
        })
        try! library.sources.forEach({(id: String, sourceType: DocumentSource.Type) in
            let key = "\(library.id).sources.\(id)"
            guard !self.sourceTypes.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.sourceTypes[key] = sourceType
        })
        try! library.annotators.forEach({(id: String, annotatorType: DocumentAnnotator.Type) in
            let key = "\(library.id).annotators.\(id)"
            guard !self.annotatorTypes.keys.contains(key) else {
                throw LibraryManagerError.duplicate(id: key)
            }
            self.annotatorTypes[key] = annotatorType
        })
        try! library.exporters.forEach({(id: String, exporterType: DocumentExporter.Type) in
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

    func get(source key: String, with config: Configuration, uuid: UUID) -> DocumentSource {
        return self.sourceTypes[key]!.init(with: config, uuid: uuid)
    }

    func get(annotator key: String, with config: Configuration, uuid: UUID) -> DocumentAnnotator {
        return self.annotatorTypes[key]!.init(with: config, uuid: uuid)
    }

    func get(exporter key: String, with config: Configuration) -> DocumentExporter {
        return self.exporterTypes[key]!.init(with: config)
    }
}
