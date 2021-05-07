//
//  App.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 05/04/2021.
//

import SwiftUI

@main
struct PTSApp: App {
    private let configurationManager = ConfigurationManager(
            "PTSFolder",
            [
                CurrentCalendarEventsDocumentAnnotator(),
                GeoLocalizationDocumentAnnotator()
            ],
            [
                CurrentEventsDocumentIntegrator()
            ])
    private let importationManager: ImportationManager

    init() {
        configurationManager.loadTypes()
        configurationManager.loadContexts()
        configurationManager.saveTypes()
        importationManager = ImportationManager(configurationManager)

        // Creates default Document Types.
        if !FileManager.default.fileExists(atPath: configurationManager.documentFolderURL.path) {
            configurationManager.addType(with: "Carte de visite")
            configurationManager.addType(with: "Affiche evenement")
            configurationManager.addType(with: "Tableau blanc")
            configurationManager.saveTypes()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                    .environmentObject(configurationManager)
                    .environmentObject(importationManager)
        }

        Settings {
            SettingsView().environmentObject(configurationManager)
        }
    }
}


struct MainView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager

    @State private var showFilePrompt = false
    @State private var showNewContextForm = false
    @State private var newContextDescription = ""

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
                }
            }
        }.frame(width: 480, height: 300).padding()
        .sheet(isPresented: $showNewContextForm) {
            Form {
                TextField("Nom", text: $newContextDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Spacer(minLength: 50)
                    Button("Annuler") {
                        showNewContextForm = false
                        newContextDescription = ""
                    }
                    Button("Créer") {
                        configurationManager.addContext(with: newContextDescription)
                        showNewContextForm = false
                        newContextDescription = ""
                        configurationManager.currentUserContext = configurationManager.contexts.last
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(AccentButtonStyle())
                    .disabled(newContextDescription.isEmpty)
                }
            }.padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    if configurationManager.currentUserContext != nil {
                        Button("Contexte général") {
                            configurationManager.currentUserContext = nil
                        }
                    }
                    ForEach(configurationManager.contexts.filter {
                              $0.description != configurationManager.currentUserContext?.description
                        }) { context in
                        Button(context.description) {
                            configurationManager.currentUserContext = context
                        }
                    }
                    Divider()
                    Button("Créer") {
                        showNewContextForm = true
                    }
                } label: {
                    Text(configurationManager.currentUserContext?.description ?? "Contexte général")
                        .foregroundColor(.gray)
                }.frame(width: 150)

                Button(action: {}) {
                    ZStack {
                        Image(systemName: "camera")
                        // Hacky way of adding a button opening a NSMenu for Continuity Camera.
                        ContinuityCameraButton()
                            .environmentObject(configurationManager)
                    }
                }

                Button(action: { showFilePrompt = true }) {
                    Image(systemName: "internaldrive")
                }.fileImporter(isPresented: $showFilePrompt,
                               allowedContentTypes: [.content],
                               allowsMultipleSelection: true) {
                    importationManager.queue(documents: (try? $0.get()) ?? [])
                }
            }
        }
    }
}


struct SettingsView: View {
    private enum Tabs: Hashable {
        case types
        case contexts
    }

    var body: some View {
        TabView {
            DocumentTypesView()
                    .tabItem {
                        Label("Types", systemImage: "doc.on.doc.fill")
                    }
                    .tag(Tabs.types)
            UserContextsView()
                    .tabItem {
                        Label("Contextes", systemImage: "at")
                    }
                    .tag(Tabs.contexts)
        }
    }
}
