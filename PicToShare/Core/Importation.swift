//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation


/// Object responsible of the Importation process.
class ImportationManager {
    enum Error: Swift.Error {
        /// The given UUID is already used by another instance.
        case duplicateUUID
        case invalidUUID
    }

    private(set) var sources: Dictionary<UUID, DocumentSource> = [:]
    private(set) var types: Dictionary<UUID, DocumentType> = [:]

    /// Registers a Document Source instance.
    ///
    /// - Parameter source: The instance to register.
    /// - Throws: `ImportationManager.Error.duplicateUUID` if the instance's
    ///     UUID is already taken.
    func register(source: DocumentSource) throws {
        guard !sources.keys.contains(source.uuid) else {
            throw Error.duplicateUUID
        }
        sources[source.uuid] = source
        source.setImportCallback(promptDocumentType)
    }

    /// Registers a Document Type instance.
    ///
    /// - Parameter type: The instance to register.
    /// - Throws: `ImportationManager.Error.duplicateUUID` if the instance's
    ///     UUID is already taken.
    func register(type: DocumentType) throws {
        guard !types.keys.contains(type.uuid) else {
            throw Error.duplicateUUID
        }
        types[type.uuid] = type
    }

    func remove(source uuid: UUID) {
        sources.removeValue(forKey: uuid)
    }

    func remove(type uuid: UUID) {
        types.removeValue(forKey: uuid)
    }

    /// Asks the corresponding Source to provide a Document for importation.
    ///
    /// - Parameter from: The UUID of the target Source.
    /// - Throws: `Error.invalidUUID` if the UUID is invalid.
    func promptDocument(from sourceUuid: UUID) throws {
        guard let source = sources[sourceUuid] else {
            throw Error.invalidUUID
        }
        source.promptDocument(with: [:])
    }

    /// Asks the User for a Document Type for importation.
    ///
    /// - Parameter document: The Document to import.
    func promptDocumentType(_ document: AnyObject) {
        // TODO: Replace with importation window.
        try? importDocument(document, withType: types.keys.first!)
    }

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    ///   - document: The Document to import.
    ///   - withType: The Type UUID to use for importation.
    /// - Throws: `Error.invalidUUID` if the Type UUID is invalid.
    func importDocument(_ document: AnyObject, withType typeUuid: UUID) throws {
        guard let type = types[typeUuid] else {
            throw Error.invalidUUID
        }

        for annotator in type.annotators {
            try annotator.annotate(document: document, with: [:])
        }

        // TODO: Complete exportation process.
        try type.exporter!.export(document: document, with: [:])
        // TODO: Complete integration process.
    }
}

