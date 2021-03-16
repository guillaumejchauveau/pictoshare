//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import CoreFoundation


/// Provides read access to a dynamic dictionary-based configuration system to
/// the Core Objects.
///
/// The Configuration is based on a system of layers. When a Core Object wants
/// to read a value in the Configuration, the key is first searched in the
/// "outermost" layer. If it is present then the value is returned, but if it is
/// absent then the Configuration will try the next layer, and so on until the
/// key is found or there is no layer left. This system allows sharing
/// settings between Core Objects and very flexible override capabilities.
///
/// Currently, the Core defines three Layers for a given Core Object, from the
/// innermost layer to the outermost:
/// - the Default Layer: provided by the Library that provides the Core Object's
///     Type. It is a read-only layer containing default settings.
/// - the Type Layer: shared by all Object of the same Type, it can be edited by
///     the User.
/// - the Object Layer: specific to one Core Object, it can also be edited by
///     the User.
class Configuration {
    /// Helper type.
    typealias Layer = Dictionary<String, Any>

    fileprivate var layers: [SafePointer<Layer>]

    init(_ layers: [SafePointer<Layer>] = []) {
        self.layers = layers
    }

    /// Find the value of a setting in the Configuration.
    ///
    /// - Parameter key: The key of the setting.
    /// - Returns: The value, or nil if undefined.
    subscript(key: String) -> Any? {
        for layer in layers.reversed() {
            if let value = layer.pointee[key] {
                return value
            }
        }
        return nil
    }
}


/// Responsible of Core Objects configuration and storage.
class ConfigurationManager {
    /// Internal representation of a configured Core Object.
    struct CoreObjectMetadata: CustomStringConvertible {
        let classID: Library.ClassID
        var description: String
        let objectLayer: SafePointer<Configuration.Layer>

        /// Creates the metadata from persistent storage data.
        ///
        /// - Parameter rawDeclaration: The data retrieved from the persistent
        ///     storage.
        /// - Throws: `ConfigurationManager.Error.preferencesError` if the
        ///     data is invalid.
        init(_ rawDeclaration: CFPropertyList) throws {
            guard let declaration = rawDeclaration
                    as? Dictionary<String, CFPropertyList> else {
                throw ConfigurationManager.Error.preferencesError
            }

            guard let classID = declaration["classID"] as? Library.ClassID else {
                throw ConfigurationManager.Error.preferencesError
            }
            self.classID = classID

            description = declaration["description"] as? String ?? ""

            guard let objectLayer = declaration["objectLayer"]
                    as? Configuration.Layer else {
                throw ConfigurationManager.Error.preferencesError
            }
            self.objectLayer = makeSafe(objectLayer)
        }

        /// Creates metadata manually.
        ///
        /// - Parameters:
        ///   - classID: The ClassID of the Core Object's Type.
        ///   - description: A human-readable description.
        ///   - objectLayer: The Object Configuration Layer.
        init(_ classID: Library.ClassID,
             description: String = "",
             objectLayer: Configuration.Layer = [:]) {
            self.classID = classID
            self.description = description
            self.objectLayer = makeSafe(objectLayer)
        }
    }

    /// Internal representation of a configured Document Type.
    ///
    /// Compatible with the Core `DocumentType` protocol to use directly with an
    /// Importation Manager.
    struct DocumentTypeMetadata: DocumentType, CustomStringConvertible {
        let formatID: Library.ClassID
        let format: AnyClass
        var description: String
        var annotatorsMetadata: [(metadata: CoreObjectMetadata,
                                  annotator: DocumentAnnotator)] = []
        let exporterMetadata: CoreObjectMetadata
        let exporter: DocumentExporter

        var annotators: [DocumentAnnotator] {
            annotatorsMetadata.map {
                _, annotator in
                annotator
            }
        }
    }

    enum Error: Swift.Error {
        case preferencesError
    }

    private let libraryManager: LibraryManager
    private let importationManager: ImportationManager

    /// The Document Sources configured to run.
    private(set) var sources: [(metadata: CoreObjectMetadata,
                                source: DocumentSource)] = []
    /// The Document Types configured.
    private(set) var types: [DocumentTypeMetadata] = []

    /// Creates a Configuration Manager.
    ///
    /// - Parameters:
    ///   - libraryManager: A Library Manager with all the libraries loaded.
    ///   - importationManager: An Importation Manager that will be the target
    ///     of the Document Sources configured with this Configuration Manager.
    init(_ libraryManager: LibraryManager,
         _ importationManager: ImportationManager) {
        self.libraryManager = libraryManager
        self.importationManager = importationManager
    }

    /// Configures a Document Source.
    ///
    /// - Parameter metadata: The metadata necessary to create a configure the
    ///     Source.
    /// - Throws: `LibraryManager.Error.invalidClassID` if the ClassID in the
    ///     metadata is not registered in the Library Manager.
    ///     Any error thrown by the Source on initialization.
    func add(source metadata: CoreObjectMetadata) throws {
        guard let configuration = libraryManager.make(
                configuration: metadata.classID,
                withTypeProtocol: .source) else {
            throw LibraryManager.Error.invalidClassID(metadata.classID)
        }
        configuration.layers.append(metadata.objectLayer)

        let source = try libraryManager.make(
                source: metadata.classID,
                with: configuration)!
        source.setImportCallback(importationManager.promptDocumentType)

        sources.append((metadata, source))
    }

    /// Removes a configured Document Source.
    ///
    /// - Parameter index: The index of the Source in the list.
    func remove(source index: Int) {
        sources.remove(at: index)
    }

    /// Configures a Document Type.
    ///
    /// - Parameters:
    ///   - formatID: The registered ClassID of the Document Format to use.
    ///   - description: A human-readable description.
    ///   - exporter: The metadata of a Document Exporter.
    ///   - annotators: A list of metadata of Document Annotators.
    /// - Throws: `LibraryManager.Error.invalidClassID` if the ClassID of the
    ///     Format or in the metadata is not registered in the Library Manager.
    ///     Any error thrown by the Annotators or Exporter on initialization.
    func addType(_ formatID: Library.ClassID,
                 _ description: String,
                 _ exporterMeta: CoreObjectMetadata,
                 _ annotatorsMeta: [CoreObjectMetadata] = []) throws {
        guard libraryManager.validate(
                formatID, withTypeProtocol: .format) != nil else {
            throw LibraryManager.Error.invalidClassID(formatID)
        }

        guard libraryManager.isType(
                exporterMeta.classID,
                compatibleWithFormat: formatID) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        guard let exporterConfig = libraryManager.make(
                configuration: exporterMeta.classID,
                withTypeProtocol: .exporter) else {
            throw LibraryManager.Error.invalidClassID(exporterMeta.classID)
        }
        exporterConfig.layers.append(exporterMeta.objectLayer)
        let exporter = try libraryManager.make(
                exporter: exporterMeta.classID,
                with: exporterConfig)!

        var type = DocumentTypeMetadata(
                formatID: formatID,
                format: libraryManager.get(format: formatID)!,
                description: description,
                exporterMetadata: exporterMeta,
                exporter: exporter)

        for annotatorMeta in annotatorsMeta {
            guard libraryManager.isType(
                    annotatorMeta.classID,
                    compatibleWithFormat: formatID) else {
                throw DocumentFormatError.incompatibleDocumentFormat
            }
            guard let configuration = libraryManager.make(
                    configuration: annotatorMeta.classID,
                    withTypeProtocol: .annotator) else {
                throw LibraryManager.Error.invalidClassID(annotatorMeta.classID)
            }
            configuration.layers.append(annotatorMeta.objectLayer)
            let annotator = try libraryManager.make(
                    annotator: annotatorMeta.classID,
                    with: configuration)!

            type.annotatorsMetadata.append((annotatorMeta, annotator))
        }
        types.append(type)
    }

    /// Removes a configured Document Type.
    ///
    /// - Parameter index: The index of the Type in the list.
    func remove(type index: Int) {
        types.remove(at: index)
    }

    //**************************************************************************
    // The following methods are responsible of the persistence of the
    // configured Core Objects.
    //**************************************************************************

    /// Helper function to read data from key-value persistent storage.
    ///
    /// - Parameter key: The key of the value to read.
    /// - Returns: The value or nil if not found.
    private func getPreference(_ key: String) -> CFPropertyList? {
        CFPreferencesCopyAppValue(
                key as CFString,
                kCFPreferencesCurrentApplication)
    }

    /// Helper function to write data from key-value persistent storage.
    ///
    /// - Parameters:
    ///   - key: The key of the value to write.
    ///   - value: The value to write.
    private func setPreference(_ key: String, _ value: CFPropertyList) {
        CFPreferencesSetAppValue(
                key as CFString,
                value as CFPropertyList,
                kCFPreferencesCurrentApplication)
    }

    /// Helper function to load the Type Configuration Layer of a Library's set
    /// of a given Core Type Protocol.
    ///
    /// - Parameters:
    ///   - libraryID: The ID of the Library.
    ///   - typesProtocol: The Type Protocol of the Types to load the Layer of.
    ///   - types: The storage point of the Types Metadata, usually in a
    ///     Library Manager.
    private func loadTypeConfigurationLayer<T>(
            _ libraryID: String,
            _ typesProtocol: LibraryManager.CoreTypeProtocol,
            _ types: Dictionary<String, LibraryManager.CoreTypeMetadata<T>>) {
        for (typeID, typeMetadata) in types {
            let classID = "\(libraryID).\(typesProtocol).\(typeID)"
            if let typeLayer = getPreference(classID)
                    as? Configuration.Layer {
                typeMetadata.typeLayer.pointee = typeLayer
            }
        }
    }

    func loadTypeConfigurationLayers() {
        for (libraryID, library) in libraryManager.libraries {
            loadTypeConfigurationLayer(libraryID, .source, library.sourceTypes)
            loadTypeConfigurationLayer(libraryID, .annotator,
                    library.annotatorTypes)
            loadTypeConfigurationLayer(libraryID, .exporter,
                    library.exporterTypes)
        }
    }

    func loadSources() {
        sources.removeAll()
        let sourceDeclarations = getPreference("sources")
                as? Array<CFPropertyList> ?? []
        for rawDeclaration in sourceDeclarations {
            do {
                try add(source: try CoreObjectMetadata(rawDeclaration))
            } catch {
                continue
            }
        }
    }

    func loadTypes() {
        types.removeAll()
        let typeDeclarations = getPreference("types")
                as? Array<CFPropertyList> ?? []
        for rawDeclaration in typeDeclarations {
            do {
                guard let declaration = rawDeclaration
                        as? Dictionary<String, Any> else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let formatID = declaration["format"]
                        as? Library.ClassID else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let description = declaration["description"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let exporter = declaration["exporter"] else {
                    throw ConfigurationManager.Error.preferencesError
                }
                let exporterMetadata =
                        try CoreObjectMetadata(exporter as CFPropertyList)

                guard let annotators = declaration["annotators"]
                        as? Array<CFPropertyList> else {
                    throw ConfigurationManager.Error.preferencesError
                }
                var annotatorsMetadata: [CoreObjectMetadata] = []
                for annotator in annotators {
                    annotatorsMetadata.append(
                            try CoreObjectMetadata(annotator))
                }
                try addType(formatID,
                        description,
                        exporterMetadata,
                        annotatorsMetadata)
            } catch {
                continue
            }
        }
    }

    /// Configures Core Objects by reading data from persistent storage.
    func load() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        loadTypeConfigurationLayers()
        loadSources()
        loadTypes()
    }

    /// Helper function to save the Type Configuration Layer of a Library's set
    /// of a given Core Type Protocol.
    ///
    /// - Parameters:
    ///   - libraryID: The ID of the Library.
    ///   - typesProtocol: The Type Protocol of the Types to load the Layer of.
    ///   - types: The storage point of the Types Metadata, usually in a
    ///     Library Manager.
    private func saveTypeConfigurationLayer<T>(
            _ libraryID: String,
            _ typesProtocol: LibraryManager.CoreTypeProtocol,
            _ types: Dictionary<String, LibraryManager.CoreTypeMetadata<T>>) {
        for (typeID, typeMetadata) in types {
            setPreference(
                    "\(libraryID).\(typesProtocol).\(typeID)",
                    typeMetadata.typeLayer.pointee as CFPropertyList)
        }

    }

    func saveSources() {
        setPreference("sources",
                sources.map {
                    $0.metadata.toCFPropertyList()
                } as CFArray)
    }

    func saveTypes() {
        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)
    }

    func saveTypeConfigurationLayers() {
        for (libraryID, library) in libraryManager.libraries {
            saveTypeConfigurationLayer(libraryID, .source, library.sourceTypes)
            saveTypeConfigurationLayer(libraryID, .annotator,
                    library.annotatorTypes)
            saveTypeConfigurationLayer(libraryID, .exporter,
                    library.exporterTypes)
        }
    }

    /// Saves configured Core Objects to persistent storage.
    func save() {
        saveSources()
        saveTypes()
        saveTypeConfigurationLayers()
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}

extension ConfigurationManager.CoreObjectMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "classID": classID,
            "description": description,
            "objectLayer": objectLayer
        ] as CFPropertyList
    }
}

extension ConfigurationManager.DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "format": formatID,
            "description": description,
            "annotators": annotatorsMetadata.map {
                metadata, _ in
                metadata.toCFPropertyList()
            },
            "exporter": exporterMetadata.toCFPropertyList()
        ] as CFPropertyList
    }
}
