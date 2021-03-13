//
//  DocumentTypes.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

class TextDocument: CustomStringConvertible {
    let description = "Text"
    let documentName: String
    var content: String
    
    init(content: String, documentName: String) {
        self.content = content
        self.documentName = documentName
    }
}
