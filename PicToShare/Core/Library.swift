//
//  Library.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

typealias ClassID = String


/// An object providing Core types as a package.
protocol Library: CustomStringConvertible {
    /// An identifier for the library.
    var id: String { get }
    /// Formats associated to an identifier.
    var formats: Dictionary<ClassID, AnyClass> { get }
    /// Source types associated to an identifier.
    var sources: Dictionary<ClassID, DocumentSource.Type> { get }
    /// Annotator types associated to an identifier.
    var annotators: Dictionary<ClassID, DocumentAnnotator.Type> { get }
    /// Exporter types associated to an identifier.
    var exporters: Dictionary<ClassID, DocumentExporter.Type> { get }
}

extension Library {
    var formats: Dictionary<ClassID, AnyClass> {
        [:]
    }
    var sources: Dictionary<ClassID, DocumentSource.Type> {
        [:]
    }
    var annotators: Dictionary<ClassID, DocumentAnnotator.Type> {
        [:]
    }
    var exporters: Dictionary<ClassID, DocumentExporter.Type> {
        [:]
    }
}

/// Object responsible for loading libraries and providing a facade to access
/// the Core types made available.
///
/// Types are available under a classID:
/// `<library identifier>.[formats|sources|...].<type identifier>`.
class LibraryManager {
    enum Error: Swift.Error {
        /// The Type classID is already in use.
        case duplicateClassID(ClassID)
        case invalidClassID(ClassID)
    }

    private var formats: Dictionary<ClassID, AnyClass> = [:]
    private var sourceTypes: Dictionary<ClassID, DocumentSource.Type> = [:]
    private var annotatorTypes: Dictionary<ClassID, DocumentAnnotator.Type> = [:]
    private var exporterTypes: Dictionary<ClassID, DocumentExporter.Type> = [:]

    /// Loads a library by registering the Types it provides.
    ///
    /// - Parameter library: The library to load.
    /// - Throws: `LibraryManage.Error.duplicateClassID` if a new Type as the same
    ///     classID as an existing one.
    func load(library: Library) throws {
        try library.formats.forEach { id, format in
            let classID = "\(library.id).formats.\(id)"
            guard !formats.keys.contains(classID) else {
                throw Error.duplicateClassID(classID)
            }
            formats[classID] = format
        }
        try library.sources.forEach { id, sourceType in
            let classID = "\(library.id).sources.\(id)"
            guard !sourceTypes.keys.contains(classID) else {
                throw Error.duplicateClassID(classID)
            }
            sourceTypes[classID] = sourceType
        }
        try library.annotators.forEach { id, annotatorType in
            let classID = "\(library.id).annotators.\(id)"
            guard !annotatorTypes.keys.contains(classID) else {
                throw Error.duplicateClassID(classID)
            }
            annotatorTypes[classID] = annotatorType
        }
        try library.exporters.forEach { id, exporterType in
            let classID = "\(library.id).exporters.\(id)"
            guard !exporterTypes.keys.contains(classID) else {
                throw Error.duplicateClassID(classID)
            }
            exporterTypes[classID] = exporterType
        }
    }

    /// Retrieves a Format (Document class).
    ///
    /// - Parameter format: The classID of the Format.
    /// - Returns: The Format.
    func get(format classID: ClassID) -> AnyClass? {
        formats[classID]
    }

    /// Instantiates a Source Type.
    ///
    /// - Parameters:
    ///   - source: The classID of the Source Type.
    ///   - with: The Configuration for this instance.
    ///   - uuid: The UUID for this instance.
    /// - Returns: The instance.
    func make(source classID: ClassID,
              with config: Configuration,
              uuid: UUID) -> DocumentSource? {
        sourceTypes[classID]?.init(with: config, uuid: uuid)
    }

    /// Instantiates an Annotator Type.
    ///
    /// - Parameters:
    ///   - annotator: The classID of the Annotator Type.
    ///   - with: The Configuration for this instance.
    ///   - uuid: The UUID for this instance.
    /// - Returns: The instance.
    func make(annotator classID: ClassID,
              with config: Configuration,
              uuid: UUID) -> DocumentAnnotator? {
        annotatorTypes[classID]?.init(with: config, uuid: uuid)
    }

    /// Instantiates an Exporter Type.
    ///
    /// - Parameters:
    ///   - exporter: The classID of the Exporter Type.
    ///   - with: The Configuration for this instance.
    ///   - uuid: The UUID for this instance.
    /// - Returns: The instance.
    func make(exporter classID: ClassID,
              with config: Configuration,
              uuid: UUID) -> DocumentExporter? {
        exporterTypes[classID]?.init(with: config, uuid: uuid)
    }
}
