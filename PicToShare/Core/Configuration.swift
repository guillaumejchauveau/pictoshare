//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

/// Responsible of Document Types configuration and storage.
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

    /// The Document Types configured.
    private(set) var types: [DocumentTypeMetadata] = []

    /// Configures a Document Type.
    ///
    /// - Parameters:
    ///   - description: A human-readable description.
    ///   - contentAnnotatorURL: The URL of the AppleScript.
    func addType(_ description: String,
                 _ contentAnnotatorURL: URL) throws {

        types.append(DocumentTypeMetadata(
                description: description,
                contentAnnotatorScript: contentAnnotatorURL,
                contextAnnotators: []))
    }

    /// Updates the description of a configured Document Type.
    ///
    /// - Parameters:
    ///   - type: The index of the Type in the list.
    ///   - description: The new description.
    func update(type index: Int, description: String) {
        types[index].description = description
    }

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

    /// Configures Document Types by reading data from persistent storage.
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
                try addType(description, contentAnnotatorURL)
            } catch {
                continue
            }
        }
    }

    /// Saves configured Document Types to persistent storage.
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
            "contentAnnotator": contentAnnotatorScript.path
        ] as CFPropertyList
    }
}
