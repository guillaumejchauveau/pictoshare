//
//  PDF.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation

class PDFExporter: DocumentExporter {
    let description = "PDF Exporter"
    let uuid: UUID
    var compatibleFormats: [AnyClass] = [TextDocument.self]


    required init(with config: Configuration, uuid: UUID) {
        self.uuid = uuid
    }

    func export(document: AnyObject, with config: Configuration) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        print("exporter")
    }
}
