//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import CoreFoundation


///
///
class Configuration {
    fileprivate var groups: [DictionaryRef<String, Any>] = []

    subscript(key: String) -> Any? {
        for group in groups.reversed() {
            let value = group[key]
            if (value != nil) {
                return value
            }
        }
        return nil
    }
}


class ConfigurationManager {
    enum Error: Swift.Error {
        case preferencesError
        case incompleteMetadata
    }

    private let libraryManager: LibraryManager
    private let importationManager: ImportationManager

    private(set) var sources: [(metadata: DocumentSourceMetadata,
                                source: DocumentSource)] = []
    private(set) var types: [DocumentTypeMetadata] = []

    private func getPreference(_ key: String) -> CFPropertyList? {
        CFPreferencesCopyAppValue(
                key as CFString,
                kCFPreferencesCurrentApplication)
    }


    private func setPreference(_ key: String, _ value: CFPropertyList) {
        CFPreferencesSetAppValue(
                key as CFString,
                value as CFPropertyList,
                kCFPreferencesCurrentApplication)
    }

    init(_ libraryManager: LibraryManager, _ importationManager: ImportationManager) {
        self.libraryManager = libraryManager
        self.importationManager = importationManager
    }

    func add(source metadata: DocumentSourceMetadata) throws {
        guard libraryManager.contains(source: metadata.classID) else {
            throw LibraryManager.Error.invalidClassID(metadata.classID)
        }

        let configuration = Configuration()
        configuration.groups.append(libraryManager.get(
                sourceDefaults: metadata.classID)!)
        if let typeConfiguration = getPreference(metadata.classID)
                as? Dictionary<String, Any> {
            configuration.groups.append(
                    DictionaryRef<String, Any>(typeConfiguration))
        }
        configuration.groups.append(metadata.configuration)

        let source = libraryManager.make(
                source: metadata.classID,
                with: configuration)!
        source.setImportCallback(importationManager.promptDocumentType)

        sources.append((metadata, source))
    }

    func remove(source index: Int) {
        sources.remove(at: index)
    }

    func addType(_ formatID: ClassID,
                 _ description: String,
                 _ exporter: DocumentExporterMetadata,
                 _ annotators: [DocumentAnnotatorMetadata] = []) throws {
        guard libraryManager.contains(format: formatID) else {
            throw LibraryManager.Error.invalidClassID(formatID)
        }

        guard libraryManager.contains(exporter: exporter.classID) else {
            throw LibraryManager.Error.invalidClassID(exporter.classID)
        }
        let exporterConfig = Configuration()
        exporterConfig.groups.append(libraryManager.get(
                exporterDefaults: exporter.classID)!)
        if let typeConfiguration = getPreference(exporter.classID)
                as? Dictionary<String, Any> {
            exporterConfig.groups.append(
                    DictionaryRef<String, Any>(typeConfiguration))
        }
        exporterConfig.groups.append(exporter.configuration)

        var type = DocumentTypeMetadata(
                formatID,
                libraryManager.get(format: formatID)!,
                description,
                exporter,
                libraryManager.make(exporter: exporter.classID, with: exporterConfig)!)

        for annotator in annotators {
            guard libraryManager.contains(annotator: annotator.classID)
                    else {
                throw LibraryManager.Error.invalidClassID(annotator.classID)
            }

            let configuration = Configuration()
            configuration.groups.append(libraryManager.get(
                    annotatorDefaults: annotator.classID)!)
            if let typeConfiguration = getPreference(annotator.classID)
                    as? Dictionary<String, Any> {
                configuration.groups.append(
                        DictionaryRef<String, Any>(typeConfiguration))
            }
            configuration.groups.append(annotator.configuration)

            type.annotatorsMetadata.append((
                    annotator,
                    libraryManager.make(
                            annotator: annotator.classID,
                            with: configuration)!))
        }
        types.append(type)
    }

    func remove(type index: Int) {
        types.remove(at: index)
    }

    func load() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

        sources.removeAll()
        let sources = getPreference("sources") as? Array<CFPropertyList> ?? []
        for source in sources {
            do {
                try add(source: try DocumentSourceMetadata(source))
            } catch {
                continue
            }
        }

        types.removeAll()
        let types = getPreference("types") as? Array<CFPropertyList> ?? []
        for type in types {
            do {
                guard let dictionary = type
                        as? Dictionary<String, Any> else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let formatID = dictionary["format"]
                        as? ClassID else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let description = dictionary["description"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let exporter = dictionary["exporter"] else {
                    throw ConfigurationManager.Error.preferencesError
                }
                let exporterMetadata =
                        try DocumentExporterMetadata(exporter as CFPropertyList)

                guard let annotators = dictionary["annotators"]
                        as? Array<CFPropertyList> else {
                    throw ConfigurationManager.Error.preferencesError
                }
                var annotatorsMetadata: [DocumentAnnotatorMetadata] = []
                for annotator in annotators {
                    annotatorsMetadata.append(
                            try DocumentAnnotatorMetadata(annotator))
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

    func save() {
        CFPreferencesSetAppValue("sources" as CFString,
                sources.map {
                    $0.metadata.toCFPropertyList()
                } as CFArray,
                kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue("types" as CFString,
                types.map {
                    $0.toCFPropertyList()
                } as CFArray,
                kCFPreferencesCurrentApplication)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}
