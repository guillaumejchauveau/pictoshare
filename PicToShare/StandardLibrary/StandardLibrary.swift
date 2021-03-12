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
    let sources: Sources = [
        "filesystem": ("File system", FileSystemDocumentSource.self, nil)
    ]
    let annotators: Annotators = [
        "tag": ("Tag", TagAnnotator.self, nil)
    ]
    let exporters: Exporters = [
        "pdf": ("PDF", PDFExporter.self, nil)
    ]
}
