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

    typealias Formats = Dictionary<ClassID, (description: String,
                                             type: AnyClass)>
    /// Formats associated to an identifier.
    var formats: Formats { get }

    typealias Sources =
            Dictionary<ClassID, (description: String,
                                 type: DocumentSource.Type,
                                 defaults: Dictionary<String, Any>?)>
    /// Sources information associated to an identifier.
    var sources: Sources { get }

    typealias Annotators =
            Dictionary<ClassID, (description: String,
                                 type: DocumentAnnotator.Type,
                                 defaults: Dictionary<String, Any>?)>
    /// Annotators information associated to an identifier.
    var annotators: Annotators { get }

    typealias Exporters =
            Dictionary<ClassID, (description: String,
                                 type: DocumentExporter.Type,
                                 defaults: Dictionary<String, Any>?)>
    /// Exporters information associated to an identifier.
    var exporters
            : Exporters { get }
}

extension Library {
    var formats: Formats {
        [:]
    }
    var sources: Sources {
        [:]
    }
    var annotators: Annotators {
        [:]
    }
    var exporters: Exporters {
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
        case duplicateClassID(ClassID)
        case invalidClassID(ClassID)
    }

    private var formats: Library.Formats = [:]
    private var sourceTypes:
            Dictionary<ClassID, (description: String,
                                 type: DocumentSource.Type,
                                 defaults: DictionaryRef<String, Any>)> = [:]
    private var annotatorTypes:
            Dictionary<ClassID, (description: String,
                                 type: DocumentAnnotator.Type,
                                 defaults: DictionaryRef<String, Any>)> = [:]
    private var exporterTypes:
            Dictionary<ClassID, (description: String,
                                 type: DocumentExporter.Type,
                                 defaults: DictionaryRef<String, Any>)> = [:]

    /// Loads a library by registering the Types it provides.
    ///
    /// - Parameter library: The library to load.
    /// - Throws: `LibraryManage.Error.duplicateClassID` if a new Type as the
    ///     same classID as an existing one.
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
            sourceTypes[classID] = (sourceType.description,
                    sourceType.type,
                    DictionaryRef<String, Any>(sourceType.defaults ?? [:]))
        }
        try library.annotators.forEach { id, annotatorType in
            let classID = "\(library.id).annotators.\(id)"
            guard !annotatorTypes.keys.contains(classID) else {
                throw Error.duplicateClassID(classID)
            }
            annotatorTypes[classID] = (annotatorType.description,
                    annotatorType.type,
                    DictionaryRef<String, Any>(annotatorType.defaults ?? [:]))
        }
        try library.exporters.forEach { id, exporterType in
            let classID = "\(library.id).exporters.\(id)"
            guard !exporterTypes.keys.contains(classID) else {
                throw Error.duplicateClassID(classID)
            }
            exporterTypes[classID] = (exporterType.description,
                    exporterType.type,
                    DictionaryRef<String, Any>(exporterType.defaults ?? [:]))
        }
    }

    /// Test if the given classID in associated with a Format.
    ///
    /// - Parameter classID: The classID to test.
    /// - Returns: The result of the test.
    func contains(format classID: ClassID) -> Bool {
        formats.keys.contains(classID)
    }

    /// Retrieves a Format (Document class).
    ///
    /// - Parameter format: The classID of the Format.
    /// - Returns: The Format.
    func get(format classID: ClassID) -> AnyClass? {
        formats[classID]?.type
    }

    /// Retrieves a human-readable description of a Format.
    ///
    /// - Parameter classID: The classID of the Format.
    /// - Returns: The description.
    func get(formatDescription classID: ClassID) -> String? {
        formats[classID]?.description
    }

    /// Test if the given classID in associated with a Source Type.
    ///
    /// - Parameter classID: The classID to test.
    /// - Returns: The result of the test.
    func contains(source classID: ClassID) -> Bool {
        sourceTypes.keys.contains(classID)
    }

    /// Instantiates a Source Type.
    ///
    /// - Parameters:
    ///   - source: The classID of the Source Type.
    ///   - with: The Configuration for this instance.
    /// - Returns: The instance.
    func make(source classID: ClassID,
              with config: Configuration) -> DocumentSource? {
        sourceTypes[classID]?.type.init(with: config)
    }

    /// Retrieves a human-readable description of a Source Type.
    ///
    /// - Parameter classID: The classID of the Source Type.
    /// - Returns: The description.
    func get(sourceDescription classID: ClassID) -> String? {
        sourceTypes[classID]?.description
    }

    /// Retrieves the default Configuration Group of a Source Type.
    ///
    /// - Parameter classID: The classID of the Source Type.
    /// - Returns: The default Configuration Group.
    func get(sourceDefaults classID: ClassID) -> DictionaryRef<String, Any>? {
        sourceTypes[classID]?.defaults
    }

    /// Test if the given classID in associated with a Annotator Type.
    ///
    /// - Parameter classID: The classID to test.
    /// - Returns: The result of the test.
    func contains(annotator classID: ClassID) -> Bool {
        annotatorTypes.keys.contains(classID)
    }

    /// Instantiates an Annotator Type.
    ///
    /// - Parameters:
    ///   - annotator: The classID of the Annotator Type.
    ///   - with: The Configuration for this instance.
    /// - Returns: The instance.
    func make(annotator classID: ClassID,
              with config: Configuration) -> DocumentAnnotator? {
        annotatorTypes[classID]?.type.init(with: config)
    }

    /// Retrieves a human-readable description of a Annotator Type.
    ///
    /// - Parameter classID: The classID of the Annotator Type.
    /// - Returns: The description.
    func get(annotatorDescription classID: ClassID) -> String? {
        annotatorTypes[classID]?.description
    }

    /// Retrieves the default Configuration Group of a Annotator Type.
    ///
    /// - Parameter classID: The classID of the Annotator Type.
    /// - Returns: The default Configuration Group.
    func get(annotatorDefaults classID: ClassID)
                    -> DictionaryRef<String, Any>? {
        annotatorTypes[classID]?.defaults
    }

    /// Test if the given classID in associated with an Exporter Type.
    ///
    /// - Parameter classID: The classID to test.
    /// - Returns: The result of the test.
    func contains(exporter classID: ClassID) -> Bool {
        exporterTypes.keys.contains(classID)
    }

    /// Instantiates an Exporter Type.
    ///
    /// - Parameters:
    ///   - exporter: The classID of the Exporter Type.
    ///   - with: The Configuration for this instance.
    /// - Returns: The instance.
    /// - Throws: `LibraryManage.Error.invalidClassID if no types correspond to `
    ///     the given classID.
    func make(exporter classID: ClassID,
              with config: Configuration) -> DocumentExporter? {
        exporterTypes[classID]?.type.init(with: config)
    }

    /// Retrieves a human-readable description of a Exporter Type.
    ///
    /// - Parameter classID: The classID of the Exporter Type.
    /// - Returns: The description.
    func get(exporterDescription classID: ClassID) -> String? {
        exporterTypes[classID]?.description
    }

    /// Retrieves the default Configuration Group of a Exporter Type.
    ///
    /// - Parameter classID: The classID of the Exporter Type.
    /// - Returns: The default Configuration Group.
    func get(exporterDefaults classID: ClassID) -> DictionaryRef<String, Any>? {
        exporterTypes[classID]?.defaults
    }
}
