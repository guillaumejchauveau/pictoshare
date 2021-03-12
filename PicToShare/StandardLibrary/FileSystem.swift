//
//  FileSystem.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import AppKit


class FileSystemDocumentSource: DocumentSource {
    private var importCallback: ((AnyObject) -> Void)?
    private let openPanel: NSOpenPanel

    private let configuration: Configuration

    required init(with configuration: Configuration) {
        self.configuration = configuration
        openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
    }

    func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
        importCallback = callback
    }

    func promptDocument() {
        openPanel.begin(completionHandler: { [self]
            (response: NSApplication.ModalResponse) -> Void in
            if (response == NSApplication.ModalResponse.OK) {
                importCallback?(TextDocument())
            }
        })
        openPanel.runModal()
    }
}

class TagAnnotator: DocumentAnnotator {
    var compatibleFormats: [AnyClass] = [TextDocument.self]

    required init(with configuration: Configuration) {
    }

    func annotate(document: AnyObject) throws {
        guard isCompatibleWith(format: type(of: document)) else {
            throw DocumentFormatError.incompatibleDocumentFormat
        }
        print("annotator")
    }
}

