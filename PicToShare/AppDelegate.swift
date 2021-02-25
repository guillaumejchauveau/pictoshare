//
//  AppDelegate.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let libraryManager = LibraryManager()
    let importationManager = ImportationManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        try! libraryManager.load(library: StandardLibrary())


        let fs_uuid = UUID()
        try! importationManager.register(
            source: libraryManager.get(source: "standard.sources.filesystem",
                                       with: ["name": "This Mac"],
                                       uuid: fs_uuid))

        let doc_uuid = UUID()
        try! importationManager.register(
            type: DocumentType(name: "Doc",
                               uuid: doc_uuid,
                               format: libraryManager.get(format: "standard.formats.text"),
                               exporter: libraryManager.get(exporter: "standard.exporters.pdf",
                                                            with: [:])))

        importationManager.promptDocument(from: fs_uuid)
    }

    
}
