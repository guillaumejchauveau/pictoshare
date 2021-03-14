//
//  PDF.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation

class PDFExporter: DocumentExporter {
    var compatibleFormats: [AnyClass] = [TextDocument.self]

    required init(with configuration: Configuration) {
    }

    func export(document: AnyObject) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        print("exporter")
    }
}
