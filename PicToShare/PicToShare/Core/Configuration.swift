//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation
import Combine


/// Internal representation of a configured Document Type.
///
/// Conforms to the Core `DocumentType` protocol to use directly with an
/// Importation Manager.
class DocumentTypeMetadata: DocumentType, ObservableObject {
    let configurationManager: ConfigurationManager
    var savedDescription: String
    @Published var description: String
    @Published var contentAnnotatorScript: URL?
    @Published var copyBeforeScript: Bool
    @Published var contextAnnotatorNames: Set<String>
    private var subscriber: AnyCancellable!

    var contextAnnotators: [ContextAnnotator] {
        contextAnnotatorNames.map {
            configurationManager.contextAnnotators[$0]!
        }
    }

    var folder: URL {
        configurationManager.documentFolderURL.appendingPathComponent(savedDescription)
    }

    init(_ description: String,
         _ configurationManager: ConfigurationManager,
         _ contentAnnotatorScript: URL? = nil,
         _ copyBeforeScript: Bool = true,
         _ contextAnnotatorNames: Set<String> = []) {
        self.configurationManager = configurationManager
        self.description = description
        savedDescription = description
        self.contentAnnotatorScript = contentAnnotatorScript
        self.copyBeforeScript = copyBeforeScript
        self.contextAnnotatorNames = contextAnnotatorNames
        subscriber = self.objectWillChange.sink {
            DispatchQueue.main
                    .asyncAfter(deadline: .now() + .milliseconds(200)) {
                configurationManager.save(type: self)
            }
        }
    }
}

/// Responsible of Document Types configuration and storage.
class ConfigurationManager: ObservableObject {
    enum Error: Swift.Error {
        case preferencesError
    }

    let contextAnnotators: [String: ContextAnnotator]

    let documentFolderURL: URL

    /// The Document Types configured.
    @Published var types: [DocumentTypeMetadata] = []

    init(_ ptsFolderName: String, _ contextAnnotators: [ContextAnnotator] = []) {
        var annotators: [String: ContextAnnotator] = [:]
        for contextAnnotator in contextAnnotators {
            annotators[contextAnnotator.description] = contextAnnotator
        }
        self.contextAnnotators = annotators
        documentFolderURL = try! FileManager.default
                .url(for: .documentDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true)
                .appendingPathComponent(ptsFolderName, isDirectory: true)
    }

    /// Configures a new Document Type.
    func addType(with description: String) {
        types.append(DocumentTypeMetadata(description, self))
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
                value,
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
                let contentAnnotatorURL: URL?
                if let contentAnnotatorPath = declaration["contentAnnotator"]
                        as? String {
                    contentAnnotatorURL = URL(string: contentAnnotatorPath)
                } else {
                    contentAnnotatorURL = nil
                }

                let copyBeforeScript = declaration["copyBeforeScript"]
                        as? Bool ?? true

                var contextAnnotators: Set<String> = []
                let contextAnnotatorsDeclarations = declaration["contextAnnotators"]
                        as? Array<CFPropertyList> ?? []
                for rawContextAnnotatorDeclaration in contextAnnotatorsDeclarations {
                    if let contextAnnotatorDescription = rawContextAnnotatorDeclaration
                            as? String {
                        if self.contextAnnotators.keys.contains(contextAnnotatorDescription) {
                            contextAnnotators.insert(contextAnnotatorDescription)
                        }
                    }
                }

                types.append(DocumentTypeMetadata(description,
                        self,
                        contentAnnotatorURL,
                        copyBeforeScript,
                        contextAnnotators))
            } catch {
                continue
            }
        }
    }

    /// Updates the folder corresponding to the given Document Type.
    /// Currently as multiple failing situations:
    /// - a file exists with the name of the document type;
    /// - the name of the document type contains forbidden characters for paths;
    /// - two document types have the same name.
    private func updateTypeFolder(_ type: DocumentTypeMetadata) {
        let newUrl = documentFolderURL.appendingPathComponent(type.description)
        let oldUrl = documentFolderURL.appendingPathComponent(type.savedDescription)
        if !FileManager.default.fileExists(atPath: oldUrl.path) {
            try! FileManager.default.createDirectory(at: newUrl, withIntermediateDirectories: true)
        } else {
            if type.savedDescription != type.description {
                do {
                    try FileManager.default.moveItem(at: oldUrl, to: newUrl)
                    type.savedDescription = type.description
                } catch {
                    type.description = type.savedDescription
                }
            }
        }
    }

    /// Saves the given Document Type to persistent storage
    func save(type: DocumentTypeMetadata) {
        updateTypeFolder(type)

        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    /// Saves all the configured Document Types.
    func saveAll() {
        for type in types {
            updateTypeFolder(type)
        }
        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}


extension DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "contentAnnotator": contentAnnotatorScript?.path ?? "",
            "copyBeforeScript": copyBeforeScript,
            "contextAnnotators": contextAnnotators.map({ $0.description }) as CFArray
        ] as CFPropertyList
    }
}
