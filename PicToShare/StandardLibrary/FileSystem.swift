//
//  FileSystem.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import AppKit


class FileSystemDocumentSource: DocumentSource {
    let uuid: UUID
    let description: String
    private var importCallback: ((AnyObject) -> Void)?
    private let openPanel: NSOpenPanel

    required init(with config: Configuration, uuid: UUID) {
        self.uuid = uuid
        description = config["name"]!
        openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
    }

    func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
        importCallback = callback
    }

    func promptDocument(with config: Configuration) {
        openPanel.begin(completionHandler: { [self]
            (response: NSApplication.ModalResponse) -> Void in
            if (response == NSApplication.ModalResponse.OK) {
                importCallback?(TextDocument())
            }
        })
        openPanel.runModal()
    }
}

struct TagAnnotator: DocumentAnnotator {
    let uuid: UUID
    let description: String
    var compatibleFormats: [AnyClass] = [TextDocument.self]

    init(with config: Configuration, uuid: UUID) {
        self.uuid = uuid
        description = config["name"]!
    }

    func annotate(document: AnyObject, with config: Configuration) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        print("annotator")
    }
}

