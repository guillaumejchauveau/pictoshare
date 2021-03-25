//
//  AppDelegate.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let importationManager = ImportationManager()
    var configurationManager: ConfigurationManager
    var fsSource: FileSystemDocumentSource?

    override init() {
        configurationManager = ConfigurationManager(
                importationManager)
        importationManager.setConfigurationManager(configurationManager)
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        fsSource = try! FileSystemDocumentSource(path: "PTSFolder")
        fsSource?.setImportCallback(importationManager.promptDocumentType)
        try! configurationManager.addType("Fichier texte", URL(fileURLWithPath: "/"))
    }
}
