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
                source: libraryManager.make(
                        source: "standard.sources.filesystem",
                        with: ["name": "This Mac"],
                        uuid: fs_uuid)!)

        var doc = DocumentType(
                description: "Doc",
                uuid: UUID(),
                format: libraryManager.get(format: "standard.formats.text")!)
        try! doc.set(
                exporter: libraryManager.make(
                        exporter: "standard.exporters.pdf",
                        with: [:],
                        uuid: UUID())!)
        try! importationManager.register(type: doc)

        // try! importationManager.promptDocument(from: fs_uuid)
    }
}
