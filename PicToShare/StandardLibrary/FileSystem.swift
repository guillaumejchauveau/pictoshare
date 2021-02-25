//
//  FileSystem.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import AppKit


class FileSystemDocumentSource: DocumentSource {
    let description: String
    var importCallback: ((AnyObject) -> ())?
    private let openPanel: NSOpenPanel

    required init(with config: Configuration) {
        self.description = config["name"]!
        self.openPanel = NSOpenPanel()
        self.openPanel.canChooseDirectories = false
        self.openPanel.allowsMultipleSelection = false
    }

    func promptForDocument(with config: Configuration) {
        openPanel.begin(completionHandler: { (response: NSApplication.ModalResponse) -> Void in
            if (response == NSApplication.ModalResponse.OK) {
                print(self.openPanel.urls)
            }
        })
        openPanel.runModal()
    }


}

class TagAnnotator: DocumentAnnotator {
    let description: String
    var compatibleFormats: [AnyClass] = [TextDocument.self]

    required init(with config: Configuration) {
        self.description = config["name"]!
    }

    func annotate(document: AnyObject, with config: Configuration) throws {
        guard self.isCompatibleWith(format: type(of: document)) else {
            throw DocumentAnnotatorError.imcompatibleDocumentFormat
        }
        print("annotator")
    }
}

