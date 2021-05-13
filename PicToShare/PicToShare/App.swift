import SwiftUI

@main
struct PTSApp: App {
    private let configurationManager: ConfigurationManager
    private let importationManager = ImportationManager()

    private let calendarResource = CalendarsResource()

    private let statusItem: NSStatusItem
    private let statusItemMenuDelegate: StatusMenuDelegate

    private let servicesProvider: ServicesProvider

    /// Opens the PTS application from anywhere.
    static func openPTS() {
        NSWorkspace.shared.open(URL(string: "pictoshare://main")!)
    }

    /// PTS entry point.
    /// Initializes application managers and OS integrations.
    init() {
        configurationManager = ConfigurationManager(
                "PTSFolder", // Name for the main PicToShare folder.
                "Continuity", // Name for the sub-folder where Continuity Camera Documents are saved.
                [// List of available Document Annotators.
                    CurrentCalendarEventsDocumentAnnotator(calendarResource),
                    GeoLocalizationDocumentAnnotator()
                ],
                [// List of available Document Integrators.
                    CurrentCalendarEventsDocumentIntegrator(calendarResource)
                ],
                calendarResource)
        // Loads the configuration from persistent storage and creates folders
        // if necessary.
        configurationManager.loadTypes()
        configurationManager.loadContexts()
        configurationManager.saveTypes()

        calendarResource.refreshCalendars()

        // Creates default Document Types.
        if !FileManager.default.fileExists(
                atPath: configurationManager.documentFolderURL.path) {
            configurationManager.addType(with: NSLocalizedString("pts.defaultDocumentTypes.1", comment: ""))
            configurationManager.addType(with: NSLocalizedString("pts.defaultDocumentTypes.2", comment: ""))
            configurationManager.addType(with: NSLocalizedString("pts.defaultDocumentTypes.3", comment: ""))
            configurationManager.saveTypes()
        }

        // Forces NSApplication initialization now, required for next steps.
        // This step is normally performed after the App object initialization
        // in the default main function.
        NSApp = NSApplication.shared

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(named: "StatusItemIcon")
        statusItem.menu = NSMenu()
        statusItemMenuDelegate = StatusMenuDelegate(configurationManager, statusItem.menu!)

        servicesProvider = ServicesProvider(importationManager)
    }

    var body: some Scene {
        // Main window opened by PTSApp.openPTS().
        WindowGroup {
            MainView()
                    .environmentObject(configurationManager)
                    .environmentObject(importationManager)
                    .handlesExternalEvents(
                            preferring: Set(arrayLiteral: "main"),
                            allowing: Set(arrayLiteral: "*"))
        }.handlesExternalEvents(matching: Set(arrayLiteral: "main"))

        Settings {
            SettingsView()
                    .environmentObject(configurationManager)
                    .environmentObject(calendarResource)
        }
    }
}


struct MainView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager

    /// State of the file system importation window.
    @State private var showFilePrompt = false
    /// State of the user context create sheet.
    @State private var showNewContextForm = false
    /// Field data for the user context create sheet.
    @State private var newContextDescription = ""

    var body: some View {
        HStack {
            if importationManager.queueHead != nil {
                ImportationView()
            } else {
                // Landing view if no documents are queued for importation.
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
                // User context create sheet. Allows the user to create a new
                // context from the main window.
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
                // Main window toolbar.
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        // User context selection menu.
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
                            // Button for the user context creation sheet.
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

                        // Continuity Camera importation button.
                        Button(action: {}) {
                            ZStack {
                                Image(systemName: "camera")
                                // Hacky way of adding a button opening a NSMenu for Continuity Camera.
                                ContinuityCameraButton()
                            }
                        }

                        // File system importation button
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
        case documentTypes
        case userContexts
    }

    var body: some View {
        TabView {
            DocumentTypesView()
                    .tabItem {
                        Label("pts.documentTypes", systemImage: "doc.on.doc.fill")
                    }
                    .tag(Tabs.documentTypes)
            UserContextsView()
                    .tabItem {
                        Label("pts.userContexts", systemImage: "at")
                    }
                    .tag(Tabs.userContexts)
        }.frame(width: 700, height: 400)
    }
}
