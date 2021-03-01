//
//  Library.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation


/// An object providing Core types as a package.
protocol Library: CustomStringConvertible {
    /// An identifier for the library.
    var id: String { get }
    /// Formats associated to an identifier.
    var formats: Dictionary<String, AnyClass> { get }
    /// Source types associated to an identifier.
    var sources: Dictionary<String, DocumentSource.Type> { get }
    /// Annotator types associated to an identifier.
    var annotators: Dictionary<String, DocumentAnnotator.Type> { get }
    /// Exporter types associated to an identifier.
    var exporters: Dictionary<String, DocumentExporter.Type> { get }
}

/// Object responsible for loading libraries and providing a facade to access
/// the Core types made available.
///
/// Types are available under a Path:
/// `<library identifier>.[formats|sources|...].<type identifier>`.
class LibraryManager {
    enum Error: Swift.Error {
        /// The Type Path is already in use.
        case duplicatePath(String)
        case invalidPath(String)
    }

    private var formats: Dictionary<String, AnyClass> = [:]
    private var sourceTypes: Dictionary<String, DocumentSource.Type> = [:]
    private var annotatorTypes: Dictionary<String, DocumentAnnotator.Type> = [:]
    private var exporterTypes: Dictionary<String, DocumentExporter.Type> = [:]

    /// Loads a library by registering the Types it provides.
    ///
    /// - Parameter library: The library to load.
    /// - Throws: `LibraryManage.Error.duplicatePath` if a new Type as the same
    ///     Path as an existing one.
    func load(library: Library) throws {
        try library.formats.forEach({
            (id: String, format: AnyClass) in

            let path = "\(library.id).formats.\(id)"
            guard !formats.keys.contains(path) else {
                throw Error.duplicatePath(path)
            }
            formats[path] = format
        })
        try library.sources.forEach({
            (id: String, sourceType: DocumentSource.Type) in

            let path = "\(library.id).sources.\(id)"
            guard !sourceTypes.keys.contains(path) else {
                throw Error.duplicatePath(path)
            }
            sourceTypes[path] = sourceType
        })
        try library.annotators.forEach({
            (id: String, annotatorType: DocumentAnnotator.Type) in

            let path = "\(library.id).annotators.\(id)"
            guard !annotatorTypes.keys.contains(path) else {
                throw Error.duplicatePath(path)
            }
            annotatorTypes[path] = annotatorType
        })
        try library.exporters.forEach({
            (id: String, exporterType: DocumentExporter.Type) in

            let path = "\(library.id).exporters.\(id)"
            guard !exporterTypes.keys.contains(path) else {
                throw Error.duplicatePath(path)
            }
            exporterTypes[path] = exporterType
        })
    }

    /// Retrieves a Format (Document class).
    ///
    /// - Parameter format: The Path of the Format.
    /// - Returns: The Format.
    func get(format path: String) -> AnyClass? {
        formats[path]
    }

    /// Instantiates a Source Type.
    ///
    /// - Parameters:
    ///   - source: The Path of the Source Type.
    ///   - with: The Configuration for this instance.
    ///   - uuid: The UUID for this instance.
    /// - Returns: The instance.
    func make(source path: String,
              with config: Configuration,
              uuid: UUID) -> DocumentSource? {
        sourceTypes[path]?.init(with: config, uuid: uuid)
    }

    /// Instantiates an Annotator Type.
    ///
    /// - Parameters:
    ///   - annotator: The Path of the Annotator Type.
    ///   - with: The Configuration for this instance.
    ///   - uuid: The UUID for this instance.
    /// - Returns: The instance.
    func make(annotator path: String,
              with config: Configuration,
              uuid: UUID) -> DocumentAnnotator? {
        annotatorTypes[path]?.init(with: config, uuid: uuid)
    }

    /// Instantiates an Exporter Type.
    ///
    /// - Parameters:
    ///   - exporter: The Path of the Exporter Type.
    ///   - with: The Configuration for this instance.
    ///   - uuid: The UUID for this instance.
    /// - Returns: The instance.
    func make(exporter path: String,
              with config: Configuration,
              uuid: UUID) -> DocumentExporter? {
        exporterTypes[path]?.init(with: config, uuid: uuid)
    }
}
