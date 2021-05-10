import SwiftUI

@main
struct PTSApp: App {
    private let configurationManager = ConfigurationManager(
            "PTSFolder",
            "Continuity",
            [
                CurrentCalendarEventsDocumentAnnotator(),
                GeoLocalizationDocumentAnnotator()
            ],
            [
                CurrentCalendarEventsDocumentIntegrator()
            ])
    private let importationManager: ImportationManager

    private let statusItem: NSStatusItem
    private let statusItemMenuDelegate: StatusMenuDelegate

    private let servicesProvider: ServicesProvider

    static func openPTSUrl() {
        NSWorkspace.shared.open(URL(string: "pictoshare://main")!)
    }

    init() {
        configurationManager.loadTypes()
        configurationManager.loadContexts()
        configurationManager.saveTypes()

        importationManager = ImportationManager(configurationManager)

        // Creates default Document Types.
        if !FileManager.default.fileExists(
                atPath: configurationManager.documentFolderURL.path) {
            configurationManager.addType(with: "Carte de visite")
            configurationManager.addType(with: "Affiche événement")
            configurationManager.addType(with: "Tableau blanc")
            configurationManager.saveTypes()
        }

        // Forces initialization.
        NSApp = NSApplication.shared

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(named: "StatusItemIcon")
        statusItem.menu = NSMenu()
        statusItemMenuDelegate = StatusMenuDelegate(configurationManager, statusItem.menu!)

        servicesProvider = ServicesProvider(importationManager)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                    .environmentObject(configurationManager)
                    .environmentObject(importationManager)
                    .handlesExternalEvents(
                            preferring: Set(arrayLiteral: "main"),
                            allowing: Set(arrayLiteral: "*"))
        }.handlesExternalEvents(matching: Set(arrayLiteral: "main"))

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
            } else {
                VStack(alignment: .leading) {
                    Text("pts.landing.title")
                            .font(.system(size: 20))
                            .padding(.bottom, 10)
                    HStack {
                        Image(systemName: "camera").imageScale(.large)
                                .font(.system(size: 16))
                        Text("pts.landing.continuity")
                                .font(.system(size: 16, weight: .light))
                    }
                            .padding(.bottom, 5)
                    HStack {
                        Image(systemName: "internaldrive").imageScale(.large)
                                .font(.system(size: 16))
                        Text("pts.landing.filesystem")
                                .font(.system(size: 16, weight: .light))
                    }
                }
            }
        }.frame(width: 480, height: 300).padding()
                .sheet(isPresented: $showNewContextForm) {
                    Form {
                        TextField("name", text: $newContextDescription)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack {
                            Spacer(minLength: 50)
                            Button("cancel") {
                                showNewContextForm = false
                                newContextDescription = ""
                            }
                            Button("create") {
                                configurationManager.addContext(with: newContextDescription)
                                showNewContextForm = false
                                newContextDescription = ""
                                configurationManager.currentUserContext = configurationManager.contexts.last
                            }
                                    .buttonStyle(AccentButtonStyle())
                                    .disabled(newContextDescription.isEmpty)
                        }
                    }.padding()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Menu {
                            if configurationManager.currentUserContext != nil {
                                Button("pts.userContext.nil") {
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
                            Button("add") {
                                showNewContextForm = true
                            }
                        } label: {
                            if let currentUserContextDescription = configurationManager.currentUserContext?.description {
                                Text(currentUserContextDescription)
                                        .foregroundColor(.gray)
                            } else {
                                Text("pts.userContext.nil")
                                        .foregroundColor(.gray)
                            }
                        }.frame(width: 150)

                        Button(action: {}) {
                            ZStack {
                                Image(systemName: "camera")
                                // Hacky way of adding a button opening a NSMenu for Continuity Camera.
                                ContinuityCameraButton()
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
                        Label("pts.documentTypes", systemImage: "doc.on.doc.fill")
                    }
                    .tag(Tabs.types)
            UserContextsView()
                    .tabItem {
                        Label("pts.userContexts", systemImage: "at")
                    }
                    .tag(Tabs.contexts)
        }.frame(width: 700, height: 400)
    }
}
