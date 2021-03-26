//
//  AppDelegate.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let importationManager: ImportationManager
    let configurationManager = ConfigurationManager()
    var fsSource: FileSystemDocumentSource?

    override init() {
        importationManager = ImportationManager(configurationManager)
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        fsSource = try! FileSystemDocumentSource(path: "PTSFolder")
        fsSource?.setImportCallback(importationManager.promptDocumentType)
        try! configurationManager.addType("Fichier texte", URL(fileURLWithPath: "/"))
    }
}
