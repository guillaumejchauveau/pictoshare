//
//  PDF.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//


class PDFExporter: DocumentExporter {
    let description: String
    var compatibleFormats: [AnyClass] = [TextDocument.self]


    required init(with config: Configuration) {
        self.description = config["name"]!
    }

    func export(document: AnyObject, with config: Configuration) throws {
        guard self.isCompatibleWith(format: type(of: document)) else {
            throw DocumentExporterError.imcompatibleDocumentFormat
        }
        print("exporter")
    }
}
