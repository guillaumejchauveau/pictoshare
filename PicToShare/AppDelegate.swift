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
    var configurationManager: ConfigurationManager

    override init() {
        configurationManager = ConfigurationManager(
                libraryManager,
                importationManager)
        importationManager.setConfigurationManager(configurationManager)
        super.init()
    }

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        try! libraryManager.load(library: StandardLibrary())
        try! configurationManager.add(
                source: ConfigurationManager.CoreObjectMetadata(
                        "standard.source.filesystem"))
        try! configurationManager.addType(
                "standard.format.text",
                "Fichier texte",
                ConfigurationManager.CoreObjectMetadata(
                        "standard.exporter.pdf"))

        configurationManager.sources[0].source.promptDocument()
    }
}
