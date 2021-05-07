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
    @Published var documentProcessorScript: URL?
    @Published var copyBeforeProcessing: Bool
    @Published var removeOriginalOnProcessingByproduct: Bool
    @Published var documentAnnotatorNames: Set<String>
    @Published var documentIntegratorNames: Set<String>
    private var subscriber: AnyCancellable!

    var documentAnnotators: [DocumentAnnotator] {
        documentAnnotatorNames.map {
            configurationManager.documentAnnotators[$0]!
        }
    }

    var documentIntegrators: [DocumentIntegrator] {
        documentIntegratorNames.map {
            configurationManager.documentIntegrators[$0]!
        }
    }

    var folder: URL {
        configurationManager.documentFolderURL.appendingPathComponent(savedDescription)
    }

    init(_ description: String,
         _ configurationManager: ConfigurationManager,
         _ contentAnnotatorScript: URL? = nil,
         _ copyBeforeProcessing: Bool = true,
         _ removeOriginalOnProcessingByproduct: Bool = false,
         _ documentAnnotatorNames: Set<String> = [],
         _ documentIntegratorNames: Set<String> = []) {
        self.configurationManager = configurationManager
        self.description = description
        savedDescription = description
        self.documentProcessorScript = contentAnnotatorScript
        self.copyBeforeProcessing = copyBeforeProcessing
        self.removeOriginalOnProcessingByproduct = removeOriginalOnProcessingByproduct
        self.documentAnnotatorNames = documentAnnotatorNames
        self.documentIntegratorNames = documentIntegratorNames
        subscriber = self.objectWillChange.sink {
            DispatchQueue.main
                    .asyncAfter(deadline: .now() + .milliseconds(200)) {
                configurationManager.save(type: self)
            }
        }
    }
}

class ImportationContextMetadata: UserContext, ObservableObject, Equatable, Identifiable {
    static func == (lhs: ImportationContextMetadata, rhs: ImportationContextMetadata) -> Bool {
        lhs.description == rhs.description
    }

    let configurationManager: ConfigurationManager
    var savedDescription: String
    @Published var description: String
    @Published var documentAnnotatorNames: Set<String>
    @Published var documentIntegratorNames: Set<String>
    private var subscriber: AnyCancellable!

    var documentAnnotators: [DocumentAnnotator] {
        documentAnnotatorNames.map {
            configurationManager.documentAnnotators[$0]!
        }
    }

    var documentIntegrators: [DocumentIntegrator] {
        documentIntegratorNames.map {
            configurationManager.documentIntegrators[$0]!
        }
    }

    init(_ description: String,
         _ configurationManager: ConfigurationManager,
         _ documentAnnotatorNames: Set<String> = [],
         _ documentIntegratorNames: Set<String> = []) {
        self.configurationManager = configurationManager
        self.description = description
        savedDescription = description
        self.documentAnnotatorNames = documentAnnotatorNames
        self.documentIntegratorNames = documentIntegratorNames
        subscriber = self.objectWillChange.sink {
            DispatchQueue.main
                .asyncAfter(deadline: .now() + .milliseconds(200)) {
                    configurationManager.saveContexts()
                }
        }
    }
}

/// Responsible of Document Types configuration and storage.
class ConfigurationManager: ObservableObject {
    enum Error: Swift.Error {
        case preferencesError
    }

    var documentAnnotators: [String: DocumentAnnotator]
    var documentIntegrators: [String: DocumentIntegrator]

    let documentFolderURL: URL

    /// The configured Document Types.
    @Published var types: [DocumentTypeMetadata] = []

    /// The configured Importation Contexts.
    @Published var contexts: [ImportationContextMetadata] = []

    private var currentContext_: ImportationContextMetadata? = nil
    var currentUserContext: ImportationContextMetadata? {
        get {
            currentContext_
        }
        set {
            currentContext_ = newValue
            setPreference("currentUserContext", (newValue?.description ?? "") as CFString)
            objectWillChange.send()
        }
    }

    init(_ ptsFolderName: String,
         _ contextAnnotators: [DocumentAnnotator] = [],
         _ documentIntegrators: [DocumentIntegrator] = []) {
        var annotators: [String: DocumentAnnotator] = [:]
        for contextAnnotator in contextAnnotators {
            annotators[contextAnnotator.description] = contextAnnotator
        }
        self.documentAnnotators = annotators
        var integrators: [String: DocumentIntegrator] = [:]
        for documentIntegrator in documentIntegrators {
            integrators[documentIntegrator.description] = documentIntegrator
        }
        self.documentIntegrators = integrators
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
        saveTypes()
    }

    func removeType(at index: Int) {
        types.remove(at: index)
        saveTypes()
    }

    /// Configures a new Importation Context.
    func addContext(with description: String) {
        contexts.append(ImportationContextMetadata(description, self))
        saveContexts()
    }

    func removeContext(at index: Int) {
        let context = contexts.remove(at: index)
        if currentUserContext == context {
            currentUserContext = nil
        }
        saveContexts()
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
    func loadTypes() {
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

                let documentProcessorScript: URL?
                if let scriptPath = declaration["documentProcessorScript"]
                        as? String {
                    documentProcessorScript = URL(string: scriptPath)
                } else {
                    documentProcessorScript = nil
                }

                let copyBeforeProcessing = declaration["copyBeforeProcessing"]
                        as? Bool ?? true

                let removeOriginalOnProcessingByproduct = declaration["removeOriginalOnProcessingByproduct"]
                    as? Bool ?? false

                var documentAnnotators: Set<String> = []
                let documentAnnotatorDeclarations = declaration["documentAnnotators"]
                        as? Array<CFPropertyList> ?? []
                for rawDocumentAnnotatorDeclaration in documentAnnotatorDeclarations {
                    if let annotatorDescription = rawDocumentAnnotatorDeclaration
                            as? String {
                        if self.documentAnnotators.keys.contains(annotatorDescription) {
                            documentAnnotators.insert(annotatorDescription)
                        }
                    }
                }

                var documentIntegrators: Set<String> = []
                let documentIntegratorDeclarations = declaration["documentIntegrators"]
                        as? Array<CFPropertyList> ?? []
                for rawDocumentIntegratorDeclaration in documentIntegratorDeclarations {
                    if let documentIntegratorDescription = rawDocumentIntegratorDeclaration
                            as? String {
                        if self.documentIntegrators.keys.contains(documentIntegratorDescription) {
                            documentIntegrators.insert(documentIntegratorDescription)
                        }
                    }
                }

                types.append(DocumentTypeMetadata(description,
                        self,
                        documentProcessorScript,
                        copyBeforeProcessing,
                        removeOriginalOnProcessingByproduct,
                        documentAnnotators,
                        documentIntegrators))
            } catch {
                continue
            }
        }
    }

    /// Configures Importation Contexts by reading data from persistent storage.
    func loadContexts() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

        contexts.removeAll()
        let contextDeclarations = getPreference("contexts")
            as? Array<CFPropertyList> ?? []
        for rawDeclaration in contextDeclarations {
            do {
                guard let declaration = rawDeclaration
                        as? Dictionary<String, Any> else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let description = declaration["description"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }

                var documentAnnotators: Set<String> = []
                let annotatorDeclarations = declaration["documentAnnotators"]
                    as? Array<CFPropertyList> ?? []
                for rawAnnotatorDeclaration in annotatorDeclarations {
                    if let annotatorDescription = rawAnnotatorDeclaration
                        as? String {
                        if self.documentAnnotators.keys.contains(annotatorDescription) {
                            documentAnnotators.insert(annotatorDescription)
                        }
                    }
                }

                var documentIntegrators: Set<String> = []
                let documentIntegratorDeclarations = declaration["documentIntegrators"]
                    as? Array<CFPropertyList> ?? []
                for rawDocumentIntegratorDeclaration in documentIntegratorDeclarations {
                    if let documentIntegratorDescription = rawDocumentIntegratorDeclaration
                        as? String {
                        if self.documentIntegrators.keys.contains(documentIntegratorDescription) {
                            documentIntegrators.insert(documentIntegratorDescription)
                        }
                    }
                }

                contexts.append(ImportationContextMetadata(description,
                                                  self,
                                                  documentAnnotators,
                                                  documentIntegrators))
            } catch {
                continue
            }
        }

        if let savedCurrentDescription = getPreference("currentUserContext") as? String {
            currentUserContext = contexts.first {
                $0.description == savedCurrentDescription
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
    func saveTypes() {
        for type in types {
            updateTypeFolder(type)
        }
        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    /// Saves all the configured Contexts.
    func saveContexts() {
        setPreference("contexts",
                      contexts.map {
                        $0.toCFPropertyList()
                      } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}


extension DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "documentProcessorScript": documentProcessorScript?.path ?? "",
            "copyBeforeProcessing": copyBeforeProcessing,
            "removeOriginalOnProcessingByproduct": removeOriginalOnProcessingByproduct,
            "documentAnnotators": documentAnnotators.map({ $0.description }) as CFArray,
            "documentIntegrators": documentIntegrators.map({ $0.description }) as CFArray
        ] as CFPropertyList
    }
}

extension ImportationContextMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "documentAnnotators": documentAnnotators.map({ $0.description }) as CFArray,
            "documentIntegrators": documentIntegrators.map({ $0.description }) as CFArray
        ] as CFPropertyList
    }
}
