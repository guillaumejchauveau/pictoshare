//
//  AppDelegate.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let libraryManager = LibraryManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        try! libraryManager.load(library: StandardLibrary())

        let source = libraryManager.get(source: "standard.sources.filesystem", with: ["name": "fs"])
        source.promptForDocument(with: [:])
    }
}
