//
//  Library.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation


/// An object providing Core Types as a package.
///
/// A Core Type is the class of an object used by the Core to create and process
/// Documents (a Core Object). These Types are provided by Libraries, not by the
/// Core, so the actual classes are not known. This is why they are called
/// "Types".
/// There are four different kinds of Core Types: Document Formats, Document
/// Sources, Document Annotators and Document Exporters. Each kind has a
/// corresponding protocol, defined in `Types.swift`, and referred as Core Type
/// Protocols.
///
/// This `Library` protocol is used to create classes like `StandardLibrary`,
/// that once instantiated provide Core Types that conform to the Core Type
/// Protocols. It consists mainly of four (optional) Dictionaries, storing
/// the necessary information needed to use the Core Types.
protocol Library: CustomStringConvertible {
    /// Identifies a specific Core Type registered in the Library Manager.
    ///
    /// A ClassID has three parts:
    /// - The Library ID, that indicates the Library that registered the Core
    ///     Type corresponding to the ClassID.
    /// - The Type Protocol, which can be either Document Format, Document
    ///     Source, Document Annotator or Document Exporter.
    /// - The Type ID, that identifies the specific Type in the Library.
    ///
    /// For example: `standard.format.text`, corresponds to the `text` Document
    /// Format in the `standard` Library.
    typealias ClassID = String

    /// An identifier for the Library.
    var id: String { get }

    /// Helper type.
    typealias Formats = Dictionary<ClassID, (description: String,
                                             type: AnyClass)>
    /// Document Formats associated to an identifier.
    var formats: Formats { get }

    /// Helper type.
    typealias SourceTypes =
            Dictionary<ClassID, (description: String,
                                 type: DocumentSource.Type,
                                 defaultLayer: Configuration.Layer?)>
    /// Document Source Types information associated to an identifier.
    var sourceTypes: SourceTypes { get }

    /// Helper type.
    typealias AnnotatorTypes =
            Dictionary<ClassID, (description: String,
                                 type: DocumentAnnotator.Type,
                                 defaultLayer: Configuration.Layer?)>
    /// Document Annotator Types information associated to an identifier.
    var annotatorTypes: AnnotatorTypes { get }

    /// Helper type.
    typealias ExporterTypes =
            Dictionary<ClassID, (description: String,
                                 type: DocumentExporter.Type,
                                 defaultLayer: Configuration.Layer?)>
    /// Document Exporter Types information associated to an identifier.
    var exporterTypes: ExporterTypes { get }
}

/// Helper extension that provides default values for the four Dictionaries of
/// a Library definition, allowing the developer to skip unnecessary
/// declarations.
extension Library {
    var formats: Formats {
        [:]
    }
    var sourceTypes: SourceTypes {
        [:]
    }
    var annotatorTypes: AnnotatorTypes {
        [:]
    }
    var exporterTypes: ExporterTypes {
        [:]
    }
}

/// Object responsible for loading Libraries and providing access to the
/// registered Core Types and utilities.
class LibraryManager {
    /// Helper for specifying a Core Type Protocol when processing ClassIDs.
    enum CoreTypeProtocol: String {
        case format = "format"
        case source = "source"
        case annotator = "annotator"
        case exporter = "exporter"
    }

    /// Internal representation of a registered Core Type.
    struct CoreTypeMetadata<T>: CustomStringConvertible {
        let description: String
        let type: T
        let defaultLayer: SafePointer<Configuration.Layer>
        var typeLayer: SafePointer<Configuration.Layer>
    }

    /// Internal representation of a registered Library.
    struct LibraryMetadata: CustomStringConvertible {
        var description: String
        var formats: Library.Formats = [:]
        var sourceTypes: Dictionary<String, CoreTypeMetadata<
                DocumentSource.Type>> = [:]
        var annotatorTypes: Dictionary<String, CoreTypeMetadata<
                DocumentAnnotator.Type>> = [:]
        var exporterTypes: Dictionary<String, CoreTypeMetadata<
                DocumentExporter.Type>> = [:]
    }

    enum Error: Swift.Error {
        case duplicateClassID(Library.ClassID)
        case invalidClassID(Library.ClassID)
    }

    /// The registered Libraries.
    var libraries: Dictionary<String, LibraryMetadata> = [:]

    /// Helper function for registering Core Types from a Library.
    private func saveCoreTypeDefinition<T>(
            _ metadataStorage: inout Dictionary<String, CoreTypeMetadata<T>>,
            _ typeId: String,
            _ typeDefinition: (description: String,
                               type: T,
                               defaultLayer: Configuration.Layer?)
    ) {
        metadataStorage[typeId] = CoreTypeMetadata<T>(
                description: typeDefinition.description,
                type: typeDefinition.type,
                defaultLayer: makeSafe(typeDefinition.defaultLayer ?? [:]),
                typeLayer: makeSafe([:]))
    }

    /// Loads a Library by registering the Core Types it provides.
    ///
    /// - Parameter library: The Library to load.
    /// - Throws: `LibraryManage.Error.duplicateClassID` if the Library has the
    ///     same ID as an existing one.
    func load(library: Library) throws {
        guard !libraries.keys.contains(library.id) else {
            throw Error.duplicateClassID(library.id)
        }
        var libraryMetadata = LibraryMetadata(description: library.description)

        for (id, format) in library.formats {
            libraryMetadata.formats[id] = format
        }
        for (id, sourceType) in library.sourceTypes {
            saveCoreTypeDefinition(
                    &libraryMetadata.sourceTypes,
                    id,
                    sourceType)
        }
        for (id, annotatorType) in library.annotatorTypes {
            saveCoreTypeDefinition(
                    &libraryMetadata.annotatorTypes,
                    id,
                    annotatorType)
        }
        for (id, exporterType) in library.exporterTypes {
            saveCoreTypeDefinition(
                    &libraryMetadata.exporterTypes,
                    id,
                    exporterType)
        }
        libraries[library.id] = libraryMetadata
    }

    /// Validates the given ClassID by checking the Library ID, Type Protocol,
    /// and the Type ID.
    ///
    /// - Parameters:
    ///   - classID: The ClassID to parse.
    ///   - typeProtocol: The Core Type Protocol the ClassID should correspond
    ///     to. Leave nil if you do not wish to validate it.
    /// - Returns: The three parts of the ClassID.
    func validate(_ classID: Library.ClassID,
                  withTypeProtocol validTypeProtocol: CoreTypeProtocol? = nil)
                    -> (libraryID: String,
                        typeProtocol: CoreTypeProtocol,
                        typeID: String)? {
        let parts = classID.split(separator: ".").map(String.init)
        guard parts.count == 3 && libraries.keys.contains(parts[0]) else {
            return nil
        }

        let libraryID = parts[0]
        let typeProtocol = CoreTypeProtocol(rawValue: parts[1])
        let typeID = parts[2]

        guard typeProtocol != nil && (validTypeProtocol == nil
                || typeProtocol == validTypeProtocol) else {
            return nil
        }

        // Avoids testing if the Type ID exists in each case of the switch.
        let contains: (String) -> Bool
        let library = libraries[libraryID]!
        switch typeProtocol! {
        case .format:
            contains = library.formats.keys.contains
        case .source:
            contains = library.sourceTypes.keys.contains
        case .annotator:
            contains = library.annotatorTypes.keys.contains
        case .exporter:
            contains = library.exporterTypes.keys.contains
        }
        guard contains(typeID) else {
            return nil
        }

        return (libraryID, typeProtocol!, typeID)
    }

    /// Retrieves a human-readable description of a Core Type.
    ///
    /// - Parameter classID: The ClassID of the Core Type.
    /// - Returns: The description.
    func get(description classID: Library.ClassID,
             withTypeProtocol validTypeProtocol: CoreTypeProtocol? = nil)
                    -> String? {
        guard let (library, typeProtocol, type) = validate(
                classID,
                withTypeProtocol: validTypeProtocol) else {
            return nil
        }
        switch typeProtocol {
        case .format:
            return libraries[library]!.formats[type]!.description
        case .source:
            return libraries[library]!.sourceTypes[type]!.description
        case .annotator:
            return libraries[library]!.annotatorTypes[type]!.description
        case .exporter:
            return libraries[library]!.exporterTypes[type]!.description
        }
    }

    /// Creates a Configuration for the specified Core Type, containing the
    /// Default Configuration Layer and the Type Configuration Layer.
    ///
    /// - Parameter classID: The ClassID of the corresponding Core Type.
    /// - Returns: The Configuration created.
    func make(configuration classID: Library.ClassID,
              withTypeProtocol validTypeProtocol: CoreTypeProtocol? = nil)
                    -> Configuration? {
        guard let (library, typeProtocol, type) = validate(classID) else {
            return nil
        }

        let configuration: Configuration
        switch typeProtocol {
        case .format:
            return nil
        case .source:
            let metadata = libraries[library]!.sourceTypes[type]!
            configuration = Configuration([metadata.defaultLayer,
                                           metadata.typeLayer])
        case .annotator:
            let metadata = libraries[library]!.annotatorTypes[type]!
            configuration = Configuration([metadata.defaultLayer,
                                           metadata.typeLayer])
        case .exporter:
            let metadata = libraries[library]!.exporterTypes[type]!
            configuration = Configuration([metadata.defaultLayer,
                                           metadata.typeLayer])
        }
        return configuration
    }

    /// Retrieves a Document Format (Document class).
    ///
    /// - Parameter format: The ClassID of the Format.
    /// - Returns: The Format.
    func get(format classID: Library.ClassID) -> AnyClass? {
        guard let (library, _, type) = validate(
                classID,
                withTypeProtocol: .format) else {
            return nil
        }
        return libraries[library]!.formats[type]!.type
    }

    /// Instantiates a Document Source Type.
    ///
    /// - Parameters:
    ///   - source: The ClassID of the Source Type.
    ///   - with: The Configuration for this instance.
    /// - Returns: The instance.
    func make(source classID: Library.ClassID,
              with config: Configuration) throws -> DocumentSource? {
        guard let (library, _, type) = validate(
                classID,
                withTypeProtocol: .source) else {
            return nil
        }
        return try libraries[library]!.sourceTypes[type]!
                .type.init(with: config)
    }

    /// Instantiates a Document Annotator Type.
    ///
    /// - Parameters:
    ///   - annotator: The ClassID of the Annotator Type.
    ///   - with: The Configuration for this instance.
    /// - Returns: The instance.
    func make(annotator classID: Library.ClassID,
              with config: Configuration) throws -> DocumentAnnotator? {
        guard let (library, _, type) = validate(
                classID,
                withTypeProtocol: .annotator) else {
            return nil
        }
        return try libraries[library]!.annotatorTypes[type]!
                .type.init(with: config)
    }

    /// Instantiates a Document Exporter Type.
    ///
    /// - Parameters:
    ///   - exporter: The ClassID of the Exporter Type.
    ///   - with: The Configuration for this instance.
    /// - Returns: The instance.
    func make(exporter classID: Library.ClassID,
              with config: Configuration) throws -> DocumentExporter? {
        guard let (library, _, type) = validate(
                classID,
                withTypeProtocol: .exporter) else {
            return nil
        }
        return try libraries[library]!.exporterTypes[type]!
                .type.init(with: config)
    }
}
