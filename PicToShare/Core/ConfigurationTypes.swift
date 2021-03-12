//
//  ConfigurationTypes.swift
//  PicToShare/Core
//
// Created by Guillaume Chauveau on 10/03/2021.
//

import CoreFoundation


struct DocumentSourceMetadata: CFPropertyListable {
    let classID: ClassID
    var description: String
    let configuration: DictionaryRef<String, Any>

    init(_ data: CFPropertyList) throws {
        guard let dictionary = data
                as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        guard let classID = dictionary["classID"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.classID = classID
        guard let description = dictionary["description"] as? String else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.description = description
        guard let configuration = dictionary["configuration"]
                as? Dictionary<String, Any> else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.configuration = DictionaryRef<String, Any>(configuration)
    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "classID": classID,
            "description": description,
            "configuration": configuration
        ] as CFPropertyList
    }
}

struct DocumentExporterMetadata {
    let classID: ClassID
    let configuration: DictionaryRef<String, Any>

    init(_ data: CFPropertyList) throws {
        guard let dictionary = data
                as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        guard let classID = dictionary["classID"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.classID = classID
        guard let configuration = dictionary["configuration"]
                as? Dictionary<String, Any> else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.configuration = DictionaryRef<String, Any>(configuration)
    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "classID": classID,
            "configuration": configuration
        ] as CFPropertyList
    }
}

struct DocumentAnnotatorMetadata {
    let classID: ClassID
    let configuration: DictionaryRef<String, Any>

    init(_ data: CFPropertyList) throws {
        guard let dictionary = data
                as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        guard let classID = dictionary["classID"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.classID = classID
        guard let configuration = dictionary["configuration"]
                as? Dictionary<String, Any> else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.configuration = DictionaryRef<String, Any>(configuration)
    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "classID": classID,
            "configuration": configuration
        ] as CFPropertyList
    }
}

struct DocumentTypeMetadata: DocumentType {
    let formatID: ClassID
    let format: AnyClass
    var description: String
    var annotatorsMetadata: [(metadata: DocumentAnnotatorMetadata,
                              annotator: DocumentAnnotator)] = []
    let exporterMetadata: DocumentExporterMetadata
    let exporter: DocumentExporter

    init(_ formatID: ClassID,
         _ format: AnyClass,
         _ description: String,
         _ exporterMetadata: DocumentExporterMetadata,
         _ exporter: DocumentExporter) {
        self.formatID = formatID
        self.format = format
        self.description = description
        self.exporterMetadata = exporterMetadata
        self.exporter = exporter
    }

    var annotators: [DocumentAnnotator] {
        annotatorsMetadata.map {
            (_, annotator) in annotator
        }
    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "format": formatID,
            "description": description,
            "annotators": annotatorsMetadata.map {
                (metadata, _) in metadata.toCFPropertyList()
            },
            "exporter": exporterMetadata.toCFPropertyList()
        ] as CFPropertyList
    }
}
