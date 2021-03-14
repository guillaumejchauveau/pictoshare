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
    var configurationManager: ConfigurationManager?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        try! libraryManager.load(library: StandardLibrary())
        configurationManager = ConfigurationManager(
                libraryManager,
                importationManager)
        try! configurationManager?.add(
                source: ConfigurationManager.CoreObjectMetadata(
                        "standard.source.filesystem"))
        try! configurationManager?.addType(
                "standard.format.text",
                "Text file to PDF",
                ConfigurationManager.CoreObjectMetadata(
                        "standard.exporter.pdf"))

        // configurationManager?.sources[0].source.promptDocument()
    }
}
