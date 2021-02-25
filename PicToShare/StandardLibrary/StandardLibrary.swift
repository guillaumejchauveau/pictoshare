//
//  StandardLibrary.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

class StandardLibrary: Library {
    let id: String = "standard"
    let description: String = "Standard"
    let formats: [(String, AnyClass)]? = [
        ("text", TextDocument.self),
        ("image", ImageDocument.self)
    ]
    let sources: [(String, DocumentSource.Type)]? = [
        ("filesystem", FileSystemDocumentSource.self)
    ]
    let annotators: [(String, DocumentAnnotator.Type)]? = [
        ("tag", TagAnnotator.self)
    ]
    let exporters: [(String, DocumentExporter.Type)]? = nil
}
