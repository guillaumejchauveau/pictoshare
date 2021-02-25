//
//  PDF.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//


class PDFExporter: DocumentExporter {
    let description = "PDF Exporter"
    var compatibleFormats: [AnyClass] = [TextDocument.self]


    required init(with config: Configuration) {
    }

    func export(document: AnyObject, with config: Configuration) throws {
        guard self.isCompatibleWith(format: type(of: document)) else {
            throw DocumentExporterError.imcompatibleDocumentFormat
        }
        print("exporter")
    }
}
