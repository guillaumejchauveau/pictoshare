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
    @State var showContinuityMenu = false

    init() {
        fsSource = try! FileSystemDocumentSource(configurationManager, importationManager)

        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Carte de visite"))
        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Affiche evenement"))
        configurationManager.types.append(ConfigurationManager.DocumentTypeMetadata("Tableau blanc"))
    }

    var body: some Scene {
        /*WindowGroup {
            VStack {
                Text("Welcome").font(.largeTitle)
                HStack {
                    *Button(action: {showContinuityMenu = true}) {
                        Text("Prendre une photo")
                    }*
                    ContinuityCameraButton()
                            .environmentObject(configurationManager)
                }
            }.frame(width: 500, height: 300)
        }*/

        WindowGroup {
            MainView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            ContinuityCameraButton()
                                    .environmentObject(configurationManager)
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Fichier") {
                                fsSource.promptDocument()
                            }
                        }
                    }
                    .environmentObject(configurationManager)
                    .environmentObject(importationManager)
                    .handlesExternalEvents(preferring: Set(arrayLiteral: "import"), allowing: Set(arrayLiteral: "*"))
        }.handlesExternalEvents(matching: Set(arrayLiteral: "import"))

        Settings {
            SettingsView()
                    .environmentObject(configurationManager)
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
                VStack {
                    Text("Rien à importer").font(.largeTitle)
                }.frame(width: 460)
            }
        }.padding().frame(height: 300)
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

