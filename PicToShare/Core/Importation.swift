//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation


/// Object responsible of the Importation process.
class ImportationManager {
    private var configurationManager: ConfigurationManager?

    func setConfigurationManager(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    /// Asks the User for a Document Type for importation.
    ///
    /// - Parameter document: The Document to import.
    func promptDocumentType(_ document: AnyObject) {
        // TODO: Replace with importation window.
        //try? importDocument(document, withType: types.keys.first!)
        print("lol")
    }

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    ///   - document: The Document to import.
    ///   - type: The Type to use for importation.
    /// - Throws: `Error.invalidUUID` if the Type UUID is invalid.
    func importDocument(_ document: AnyObject, withType type: DocumentType) throws {
        for annotator in type.annotators {
            try annotator.annotate(document: document)
        }

        // TODO: Complete exportation process.
        try type.exporter.export(document: document)
        // TODO: Complete integration process.
    }
}

