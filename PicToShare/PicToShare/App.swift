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
    private let importationManager: ImportationManager
    @Environment(\.openURL) private var openURL
    @State private var showFilePrompt = false

    init() {
        configurationManager.load()
        configurationManager.save()
        importationManager = ImportationManager(configurationManager)

        // Creates default document types.
        if !FileManager.default.fileExists(atPath: configurationManager.documentFolderURL.path) {
            configurationManager.addType(with: "Carte de visite")
            configurationManager.addType(with: "Affiche evenement")
            configurationManager.addType(with: "Tableau blanc")
            configurationManager.save()
        }
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
                                    ContinuityCameraButton()
                                            .environmentObject(configurationManager)
                                }
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {showFilePrompt = true}) {
                                Image(systemName: "internaldrive")
                            }.fileImporter(isPresented: $showFilePrompt,
                                           allowedContentTypes: [.content],
                                           allowsMultipleSelection: true) { result in
                                importationManager.queue(documents: (try? result.get()) ?? [])
                            }
                        }
                    }
                    .environmentObject(configurationManager)
                    .environmentObject(importationManager)
                    .handlesExternalEvents(preferring: Set(arrayLiteral: "*"), allowing: Set(arrayLiteral: "*"))
        }.handlesExternalEvents(matching: Set(arrayLiteral: "*"))

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
