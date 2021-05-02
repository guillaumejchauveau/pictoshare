//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation
import SwiftUI

/// Responsible of Document Types configuration and storage.
class ConfigurationManager: ObservableObject {
    /// Internal representation of a configured Document Type.
    ///
    /// Compatible with the Core `DocumentType` protocol to use directly with an
    /// Importation Manager.
    class DocumentTypeMetadata:
            DocumentType,
            CustomStringConvertible,
            ObservableObject {
        let configurationManager: ConfigurationManager
        var savedDescription: String
        @Published var description: String
        @Published var contentAnnotatorScript: URL? = nil
        @Published var contextAnnotators: [ContextAnnotator] = []
        var folder: URL {
            configurationManager.documentFolderURL.appendingPathComponent(savedDescription)
        }

        init(_ description: String,
             _ configurationManager: ConfigurationManager,
             _ contentAnnotatorScript: URL? = nil) {
            self.configurationManager = configurationManager
            self.description = description
            savedDescription = description
            self.contentAnnotatorScript = contentAnnotatorScript
        }
    }

    enum Error: Swift.Error {
        case preferencesError
    }

    @Published var documentFolderURL: URL = try! FileManager.default
            .url(for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true)
            .appendingPathComponent("PTSFolder", isDirectory: true)

    /// The Document Types configured.
    @Published var types: [DocumentTypeMetadata] = []

    func addType(with description: String) {
        types.append(DocumentTypeMetadata(description, self))
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
                value,
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
                let contentAnnotatorURL: URL?
                if let contentAnnotatorPath = declaration["contentAnnotator"]
                        as? String {
                    contentAnnotatorURL = URL(string: contentAnnotatorPath)
                } else {
                    contentAnnotatorURL = nil
                }
                types.append(DocumentTypeMetadata(description,
                                                  self,
                                                  contentAnnotatorURL))
            } catch {
                continue
            }
        }
    }

    /// Saves configured Document Types to persistent storage and manages corresponding folders.
    /// Currently as multiple failing situations:
    /// - a file exists with the name of the document type;
    /// - the name of the document type contains forbidden characters for paths;
    /// - two document types have the same name.
    func save() {
        for type in types {
            let newUrl = documentFolderURL.appendingPathComponent(type.description)
            let oldUrl = documentFolderURL.appendingPathComponent(type.savedDescription)
            if !FileManager.default.fileExists(atPath: oldUrl.path) {
                try! FileManager.default.createDirectory(at: newUrl, withIntermediateDirectories: true)
                continue
            }
            if type.savedDescription != type.description {
                do {
                    try FileManager.default.moveItem(at: oldUrl, to: newUrl)
                    type.savedDescription = type.description
                } catch {
                    type.description = type.savedDescription
                }
            }
        }

        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}


extension ConfigurationManager.DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "contentAnnotator": contentAnnotatorScript?.path ?? ""
        ] as CFPropertyList
    }
}


struct ConfigurationView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @State private var selection: Int? = nil
    @State private var showNewTypeForm = false
    @State private var newTypeDescription = ""

    var body: some View {
        VStack(alignment: .leading) {
            NavigationView {
                List {
                    ForEach(configurationManager.types.indices,
                            id: \.self) { index in
                        NavigationLink(
                                destination: DocumentTypeView(
                                        description: $configurationManager.types[index].description,
                                        scriptPath: $configurationManager.types[index].contentAnnotatorScript),
                                tag: index,
                                selection: $selection) {
                            Text(configurationManager.types[index].description)
                        }
                    }
                }
            }.sheet(isPresented: $showNewTypeForm, content: {
                VStack {
                    Form {
                        TextField("Nom du type", text: $newTypeDescription)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                    }.padding()
                    HStack {
                        Button("Annuler") {
                            showNewTypeForm = false
                            newTypeDescription = ""
                        }
                        Button("Créer") {
                            configurationManager.addType(with: newTypeDescription)
                            configurationManager.save()
                            selection = configurationManager.types.count - 1
                            showNewTypeForm = false
                            newTypeDescription = ""
                        }.buttonStyle(AccentButtonStyle())
                                .disabled(newTypeDescription.isEmpty)
                    }.padding([.leading, .bottom, .trailing])
                }
            })
            HStack {
                Button(action: { showNewTypeForm = true }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    guard let index: Int = selection else {
                        return
                    }

                    if configurationManager.types.count == 1 {
                        selection = nil
                    } else if index != 0 {
                        selection! -= 1
                    }
                    // Workaround a bug where the NavigationView won't clear the
                    // content of the destination view if we remove right after
                    // unselect.
                    DispatchQueue.main
                            .asyncAfter(deadline: .now() + .milliseconds(200)) {
                        configurationManager.types.remove(at: index)
                        configurationManager.save()
                    }
                }) {
                    Image(systemName: "minus")
                }.disabled(selection == nil)
            }.buttonStyle(BorderedButtonStyle())
                    .padding([.leading, .bottom, .trailing])
        }.frame(width: 640, height: 360)
    }
}


struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var description: String
    @Binding var scriptPath: URL?
    @State var chooseScriptFile = false

    var body: some View {
        HStack {
            /// Left part
            VStack(alignment: .trailing, spacing: 10) {
                Text("Nom du type :")
                Text("Script associé :")
            }.frame(width: 100, alignment: .trailing)

            /// Right part
            VStack(alignment: .leading) {
                TextField("Nom du type", text: $description, onCommit: {
                    configurationManager.save()
                }).frame(width: 200)

                HStack {
                    Text(scriptPath?.lastPathComponent ?? "Aucun script associé")
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.head)

                    /// Button to load an applescript.
                    Button(action: {
                        chooseScriptFile = true
                    }) {
                        Image(systemName: "folder")
                    }.fileImporter(isPresented: $chooseScriptFile, allowedContentTypes: [.osaScript]) { result in
                        scriptPath = try? result.get()
                        configurationManager.save()
                    }

                    /// Button to withdraw the current selected type's applescript
                    Button(action: {
                        scriptPath = nil
                        configurationManager.save()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }.frame(width: 200, alignment: .leading)
        }.frame(alignment: .center)
    }
}
