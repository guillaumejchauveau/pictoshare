//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation
import SwiftUI

/// Responsible of Document Types configuration and storage.
class ConfigurationManager {
    /// Internal representation of a configured Document Type.
    ///
    /// Compatible with the Core `DocumentType` protocol to use directly with an
    /// Importation Manager.
    struct DocumentTypeMetadata: DocumentType, CustomStringConvertible {
        var description: String
        let contentAnnotatorScript: URL
        var contextAnnotators: [ContextAnnotator] = []
    }

    enum Error: Swift.Error {
        case preferencesError
    }

    /// The Document Types configured.
    private(set) var types: [DocumentTypeMetadata] = []
    
    /// The Configuration Window
    private var configWindow = NSWindow()

    /// Configures a Document Type.
    ///
    /// - Parameters:
    ///   - description: A human-readable description.
    ///   - contentAnnotatorURL: The URL of the AppleScript.
    func addType(_ description: String,
                 _ contentAnnotatorURL: URL) throws {

        types.append(DocumentTypeMetadata(
                description: description,
                contentAnnotatorScript: contentAnnotatorURL,
                contextAnnotators: []))
    }

    /// Updates the description of a configured Document Type.
    ///
    /// - Parameters:
    ///   - type: The index of the Type in the list.
    ///   - description: The new description.
    func update(type index: Int, description: String) {
        types[index].description = description
    }

    /// Updates a configured Document Type by removing one of its Context
    /// Annotators.
    ///
    /// - Parameters:
    ///   - type: The index of the Type in the list.
    ///   - removeAnnotator: The index of the Annotator in the list.
    func update(type typeIndex: Int, removeAnnotator annotatorIndex: Int) {
        types[typeIndex].contextAnnotators.remove(at: annotatorIndex)
    }

    /// Removes a configured Document Type.
    ///
    /// - Parameter index: The index of the Type in the list.
    func remove(type index: Int) {
        types.remove(at: index)
    }

    //**************************************************************************
    // The following methods are responsible of the persistence of the
    // configured Core Objects.
    //**************************************************************************

    /// Helper function to read data from key-value persistent storage.
    ///
    /// - Parameter key: The key of the value to read.
    /// - Returns: The value or nil if not found.
    private func getPreference(_ key: String) -> CFPropertyList? {
        CFPreferencesCopyAppValue(
                key as CFString,
                kCFPreferencesCurrentApplication)
    }

    /// Helper function to write data from key-value persistent storage.
    ///
    /// - Parameters:
    ///   - key: The key of the value to write.
    ///   - value: The value to write.
    private func setPreference(_ key: String, _ value: CFPropertyList) {
        CFPreferencesSetAppValue(
                key as CFString,
                value as CFPropertyList,
                kCFPreferencesCurrentApplication)
    }

    /// Configures Document Types by reading data from persistent storage.
    func load() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

        types.removeAll()
        let typeDeclarations = getPreference("types")
                as? Array<CFPropertyList> ?? []
        for rawDeclaration in typeDeclarations {
            do {
                guard let declaration = rawDeclaration
                        as? Dictionary<String, Any> else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let description = declaration["description"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }

                guard let contentAnnotatorPath = declaration["contentAnnotator"]
                        as? String else {
                    throw ConfigurationManager.Error.preferencesError
                }
                guard let contentAnnotatorURL =
                URL(string: contentAnnotatorPath) else {
                    throw ConfigurationManager.Error.preferencesError
                }
                try addType(description, contentAnnotatorURL)
            } catch {
                continue
            }
        }
    }

    /// Saves configured Document Types to persistent storage.
    func save() {
        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    
    func startConfig() {
        configWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 600),
                              styleMask: [.titled, .closable, .fullSizeContentView],
                              backing: .buffered,
                              defer: true)
        configWindow.center()
        configWindow.title = "PicToShare - Configuration"
        configWindow.contentView = NSHostingView(rootView: ConfigurationView(config: self))
        configWindow.makeKeyAndOrderFront(nil)
    }
    
    func refreshWindow() {
        configWindow.close()
        startConfig()
    }
}


extension ConfigurationManager.DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "contentAnnotator": contentAnnotatorScript.path
        ] as CFPropertyList
    }
}


/// May be moved later on
/// For now :
///     - No automatic refresh when an action is done. The only way atm is to show a new window
///       but it will crash the app when closing it
///     - Impossible to detect when a NavigationLink has been selected to do a quick delete action.
///       I gave up on life on this
///     - To compensate for the lack of refreshing, maybe add some alert or little popup to notice the
///       user that his actions have been validated
private struct ConfigurationView: View {
    @State var config: ConfigurationManager
    
    var body: some View {
        NavigationView {
            VStack {
                // + AND - buttons here
                HStack {
                    /// Button to refresh the view, otherwise it won't (still doesn't work)
                    Button(action: {
                        print("Coucou le reload")
                        config.startConfig()
                        //config.refreshWindow()
                    }) {
                        Image(nsImage: NSImage.init(imageLiteralResourceName: NSImage.touchBarRefreshTemplateName) )
                    }
                    /// Button to add a type
                    NavigationLink(destination: AddTypeView(config: $config)) {
                        Image(nsImage: NSImage.init(imageLiteralResourceName: NSImage.addTemplateName) )
                    }
                    /// Button to delete a type
                    NavigationLink(destination: DeleteTypeView(config: $config)) {
                        Image(nsImage: NSImage.init(imageLiteralResourceName: NSImage.removeTemplateName) )
                    }
                }
                /// Creating a navigation link for each type present
                ForEach(0..<config.types.count) { typeIndex in
                    NavigationLink(config.types[typeIndex].description,
                                   destination: EditTypeView(config: $config, index: typeIndex))
                }
            }
        }
    }
}

private struct AddTypeView: View {
    @Binding var config: ConfigurationManager
    
    // If it isn't initialized like this, Swift will try to
    // initialize it with an attribute from the implicite init. We don't want that
    @State private var typeDescription = ""
    @State private var scriptURLasString = ""
    @State private var scriptURL : URL?
    
    private let modifyURLPanel = NSOpenPanel()
    
    var body: some View {
        VStack {
            Text("Description of the type")
            TextField("", text:$typeDescription)
            Text("URL to the Apple script")
            HStack {
                TextField("", text:$scriptURLasString)
                Button(action: {
                    /// Getting the URL from the pop-up window
                    modifyURLPanel.allowsMultipleSelection = false
                    modifyURLPanel.begin { [self] response in
                        guard response == NSApplication.ModalResponse.OK
                                      && modifyURLPanel.urls.count > 0 else {
                            return
                        }
                        /// Updating attributes visible for the user
                        scriptURL = modifyURLPanel.urls[0]
                        scriptURLasString = scriptURL!.absoluteString
                    }
                }) {
                    Text("Browse")
                }
            }
            Button(action: {
                /// Still need to add the URL
                do {
                    // Need to handle when no url is given
                   try config.addType(typeDescription, scriptURL!)
                } catch {
                    /// Maybe pop an altert ?
                    print("Error when adding new type")
                }
            }) {
                Text("Add")
            }
        }
    }
}


private struct DeleteTypeView: View {
    @Binding var config: ConfigurationManager
    
    var body: some View {
        Text("Check all types you want to delete")
        List {
            ForEach(0..<config.types.count) { index in
                HStack {
                    Text(config.types[index].description)
                    Button(action: {
                        config.remove(type: index)
                    }) {
                        Image(nsImage: NSImage.init(imageLiteralResourceName: NSImage.touchBarDeleteTemplateName))
                    }
                }
            }
        }
    }
}



private struct EditTypeView: View {
    @Binding var config : ConfigurationManager
    
    @State private var typeDescription = ""
    @State private var scriptURLasString = ""
    @State private var scriptURL : URL?
    
    var index : Int
    private let modifyURLPanel = NSOpenPanel()
    
    var body: some View {
        VStack {
            Text("Description of the type")
            TextField(config.types[index].description, text:$typeDescription)
            Text("URL to the Apple script")
            HStack {
                TextField(config.types[index].contentAnnotatorScript.absoluteString, text:$scriptURLasString)
                Button(action: {
                    /// Getting the URL from the pop-up window
                    modifyURLPanel.allowsMultipleSelection = false
                    modifyURLPanel.begin { [self] response in
                        guard response == NSApplication.ModalResponse.OK
                                      && modifyURLPanel.urls.count > 0 else {
                            return
                        }
                        /// Updating attributes visible for the user
                        scriptURL = modifyURLPanel.urls[0]
                        scriptURLasString = scriptURL!.absoluteString
                    }
                }) {
                    Text("Change")
                }
            }
            Button(action: {
                /// Still need to add the URL
                config.update(type: index, description: typeDescription)
            }) {
                Text("Modify")
            }
        }
    }
}
