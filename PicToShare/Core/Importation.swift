//
//  Core.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation



class ImportationManager {
    private var sources: Dictionary<UUID, DocumentSource> = [:]
    private var types: Dictionary<UUID, DocumentType> = [:]

    func register(source: DocumentSource) throws {
        guard !self.sources.keys.contains(source.uuid) else {
            throw UUIDError.duplicateUUID
        }
        self.sources[source.uuid] = source
        source.setImportCallback(self.promptDocumentType)
    }

    func register(type: DocumentType) throws {
        guard !self.types.keys.contains(type.uuid) else {
            throw UUIDError.duplicateUUID
        }
        self.types[type.uuid] = type
    }

    func getSources() -> [(UUID, String)] {
        return self.sources.values.reduce(into: []) { (result: inout [(UUID, String)], source: DocumentSource) in
            result.append((source.uuid, source.description))
        }
    }

    func getTypes() -> [(UUID, String)] {
        return self.types.values.reduce(into: []) { (result: inout [(UUID, String)], type: DocumentType) in
            result.append((type.uuid, type.description))
        }
    }

    func get(type uuid: UUID) -> DocumentType {
        return self.types[uuid]!
    }

    func remove(source uuid: UUID) {
        self.sources.removeValue(forKey: uuid)
    }

    func remove(type uuid: UUID) {
        self.types.removeValue(forKey: uuid)
    }

    func promptDocument(from sourceUuid: UUID) {
        self.sources[sourceUuid]!.promptDocument(with: [:])
    }

    func promptDocumentType(_ document: AnyObject) {
        self.importDocument(document, withType: self.types.keys.first!)
    }

    func importDocument(_ document: AnyObject, withType typeUuid: UUID) {
        let type = self.types[typeUuid]!

        for annotator in type.getAnnotators() {
            try! annotator.annotate(document: document, with: [:])
        }

        try! type.exporter.export(document: document, with: [:])
    }
}

