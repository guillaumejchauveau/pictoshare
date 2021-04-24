//
//  App.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/04/2021.
//

import SwiftUI

@main
class PTSApp: App {
    private let configurationManager = ConfigurationManager()
    private let importationManager = ImportationManager()
    private let fsSource: FileSystemDocumentSource
    private let ccSource: ContinuityCameraDocumentSource
    private let ccController = ContinuityCameraController()

    private let statusBarItem: NSStatusItem

    required init() {
        fsSource = try! FileSystemDocumentSource(configurationManager, importationManager)
        ccSource = ContinuityCameraDocumentSource(configurationManager)
        ccController.source = ccSource

        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Carte de visite"))
        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Affiche evenement"))
        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Tableau blanc"))

        statusBarItem = NSStatusBar.system.statusItem(
                withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "􀈄"

        statusBarItem.menu = NSMenu(title: "PicToShare")
        statusBarItem.menu!.addItem(
                withTitle: "Ouvrir PicToShare",
                action: #selector(showWindow),
                keyEquivalent: "").target = self
        statusBarItem.menu!.addItem(
                withTitle: "Choisir un fichier",
                action: #selector(statusMenuChooseFile),
                keyEquivalent: "").target = self
    }

    @objc func showWindow() {
        NSWorkspace.shared.open(URL(string: "pictoshare2://main")!)
    }

    @objc func statusMenuChooseFile() {
        fsSource.promptDocument()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {}) {
                                ZStack {
                                    Image(systemName: "camera")
                                    // Hacky way of adding a button opening a NSMenu for Continuity Camera.
                                    ccController
                                }
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: fsSource.promptDocument) {
                                Image(systemName: "internaldrive")
                            }
                        }
                    }
                    .environmentObject(configurationManager)
                    .environmentObject(importationManager)
                    .handlesExternalEvents(preferring: Set(arrayLiteral: "main"), allowing: Set(arrayLiteral: "*"))
        }.handlesExternalEvents(matching: Set(arrayLiteral: "main"))

        Settings {
            SettingsView().environmentObject(configurationManager)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager
    var body: some View {
        HStack {
            if importationManager.queueHead != nil {
                ImportationView()
                        .environmentObject(configurationManager)
                        .environmentObject(importationManager)
            } else {
                VStack(alignment: .leading) {
                    Text("Utilisez la barre d'outil pour importer").font(.system(size: 20))
                            .padding(.bottom, 10)
                    HStack {
                        Image(systemName: "camera").imageScale(.large).font(.system(size: 16))
                        Text("Prendre une photo avec un appareil connecté").font(.system(size: 16, weight: .light))
                    }
                            .padding(.bottom, 5)
                    HStack {
                        Image(systemName: "internaldrive").imageScale(.large).font(.system(size: 16))
                        Text("Choisir un ou plusieurs fichiers sur votre ordinateur").font(.system(size: 16, weight: .light))
                    }
                }.frame(width: 480, height: 300)
            }
        }.padding()
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0

    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
            Slider(value: $fontSize, in: 9...96) {
                Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
            }
        }.padding(20)
    }
}

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, types
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(Tabs.general)
            ConfigurationView()
                    .tabItem {
                        Label("Types", systemImage: "doc.on.doc.fill")
                    }
                    .tag(Tabs.types)
        }
    }
}

