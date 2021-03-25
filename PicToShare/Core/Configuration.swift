//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

/// Responsible of Core Objects configuration and storage.
class ConfigurationManager {

    /// Internal representation of a configured Document Type.
    ///
    /// Compatible with the Core `DocumentType` protocol to use directly with an
    /// Importation Manager.
    struct DocumentTypeMetadata: DocumentType, CustomStringConvertible {
        var description: String
        let contentAnnotatorScript: URL
        var contextAnnotators: [ContextAnnotator] = []
    }

    enum Error: Swift.Error {
        case preferencesError
    }

    private let importationManager: ImportationManager

    /// The Document Types configured.
    private(set) var types: [DocumentTypeMetadata] = []

    /// Creates a Configuration Manager.
    ///
    /// - Parameters:
    ///   - importationManager: An Importation Manager that will be the target
    ///     of the Document Sources configured with this Configuration Manager.
    init(_ importationManager: ImportationManager) {
        self.importationManager = importationManager
    }

    /// Configures a Document Type.
    ///
    /// - Parameters:
    ///   - description: A human-readable description.
    ///   - contentAnnotatorURL: The URL of the AppleScript.
    ///   - contextAnnotators:
    func addType(_ description: String,
                 _ contentAnnotatorURL: URL) throws {

        types.append(DocumentTypeMetadata(
                description: description,
                contentAnnotatorScript: contentAnnotatorURL,
                contextAnnotators: []))
        let typeIndex = types.count - 1
/*
        for annotatorMeta in annotatorsMeta {
            try update(type: typeIndex, addAnnotator: annotatorMeta)
        }*/
    }

    /// Updates the description of a configured Document Type.
    ///
    /// - Parameters:
    ///   - type: The index of the Type in the list.
    ///   - description: The new description.
    func update(type index: Int, description: String) {
        types[index].description = description
    }

    /// Updates a configured Document Type by adding a new Document Annotator.
    ///
    /// - Parameters:
    ///   - type: The index of the Type in the list.
    ///   - addAnnotator: The metadata of the new Annotator.
    /// - Throws:`LibraryManager.Error.invalidClassID` if the ClassID in the
    ///     metadata is not registered in the Library Manager, or
    ///     any error thrown by the Annotator on initialization.
    /*func update(type typeIndex: Int,
                addContextAnnotator metadata: CoreObjectMetadata) throws {
        guard libraryManager.isType(
                metadata.classID,
                compatibleWithFormat: types[typeIndex].formatID) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        guard let configuration = libraryManager.make(
                configuration: metadata.classID,
                withTypeProtocol: .annotator) else {
            throw LibraryManager.Error.invalidClassID(metadata.classID)
        }
        configuration.layers.append(metadata.objectLayer)
        let annotator = try libraryManager.make(
                annotator: metadata.classID,
                with: configuration)!

        types[typeIndex].annotatorsMetadata.append((metadata, annotator))
    }*/

    /// Updates a configured Document Type by removing one of its Context
    /// Annotators.
    ///
    /// - Parameters:
    ///   - type: The index of the Type in the list.
    ///   - removeAnnotator: The index of the Annotator in the list.
    func update(type typeIndex: Int, removeAnnotator annotatorIndex: Int) {
        types[typeIndex].contextAnnotators.remove(at: annotatorIndex)
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

    /// Configures Core Objects by reading data from persistent storage.
    func load() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

        types.removeAll()
        let typeDeclarations = getPreference("types")
                as? Array<CFPropertyList> ?? []
        for rawDeclaration in typeDeclarations {
            do {
                guard let declaration = rawDeclaration
                        as? Dictionary<String, Any> else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let description = declaration["description"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let contentAnnotatorPath = declaration["contentAnnotator"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }
                guard let contentAnnotatorURL =
                URL(string: contentAnnotatorPath) else {
                    throw ConfigurationManager.Error.preferencesError
                }
/*
                guard let annotators = declaration["annotators"]
                        as? Array<CFPropertyList> else {
                    throw ConfigurationManager.Error.preferencesError
                }
                var annotatorsMetadata: [CoreObjectMetadata] = []
                for annotator in annotators {
                    annotatorsMetadata.append(
                            try CoreObjectMetadata(annotator))
                }*/
                try addType(description,
                        contentAnnotatorURL)
            } catch {
                continue
            }
        }
    }

    /// Saves configured Core Objects to persistent storage.
    func save() {
        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}


extension ConfigurationManager.DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "contentAnnotator": contentAnnotatorScript.path,
            /*"annotators": contextAnnotators.map {
                metadata, _ in
                metadata.toCFPropertyList()
            }*/
        ] as CFPropertyList
    }
}
