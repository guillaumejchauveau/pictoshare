//
//  StandardLibrary.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

struct StandardLibrary: Library {
    let id: String = "standard"
    let description: String = "Standard"
    let formats: Dictionary<String, Any> = [
        "text": TextDocument.self,
        "image": ImageDocument.self
    ]
    let sources: Dictionary<String, DocumentSource.Type> = [
        "filesystem": FileSystemDocumentSource.self
    ]
    let annotators: Dictionary<String, DocumentAnnotator.Type> = [
        "tag": TagAnnotator.self
    ]
    let exporters: Dictionary<String, DocumentExporter.Type> = [
        "pdf": PDFExporter.self
    ]
}
