//
//  StandardLibrary.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

class StandardLibrary: Library {
    let id: String = "standard"
    let description: String = "Standard"
    let formats: Dictionary<String, AnyClass> = [
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
