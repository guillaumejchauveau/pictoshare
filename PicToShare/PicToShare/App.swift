//
//  App.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/04/2021.
//

import SwiftUI

@main
struct PTSApp: App {
    private let configurationManager = ConfigurationManager()
    private let importationManager = ImportationManager()
    private let fsSource: FileSystemDocumentSource
    @Environment(\.openURL) var openURL

    init() {
        fsSource = try! FileSystemDocumentSource(configurationManager, importationManager)

        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Carte de visite"))
        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Affiche evenement"))
        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Tableau blanc"))
    }

    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Welcome").font(.largeTitle)
            }.frame(width: 500, height: 300)
        }.commands {
            CommandMenu("Importer") {
                Button("Importer sur ce Mac") {
                    fsSource.promptDocument()
                }
                Divider()
                Button("Imports en attente") {
                    openURL(importationManager.importationWindowURL)
                }
            }
        }

        WindowGroup("Importation") {
            ImportationView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "import"), allowing: Set(arrayLiteral: "*"))
                .environmentObject(configurationManager)
                .environmentObject(importationManager)
        }.handlesExternalEvents(matching: Set(arrayLiteral: "import"))

        Settings {
            SettingsView()
                .environmentObject(configurationManager)
        }
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

