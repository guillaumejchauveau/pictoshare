//
//  StandardLibrary.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

struct StandardLibrary: Library {
    let id: String = "standard"
    let description: String = "Standard"
    let formats: Formats = [
        "text": ("Text", TextDocument.self),
        "image": ("Image", ImageDocument.self)
    ]
    let sourceTypes: SourceTypes = [
        "filesystem": ("File system", FileSystemDocumentSource.self, nil)
    ]
    let exporterTypes: ExporterTypes = [
        "pdf": ("PDF", PDFExporter.self, nil)
    ]
}
