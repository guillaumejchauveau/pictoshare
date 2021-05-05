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
            ObservableObject {
        let configurationManager: ConfigurationManager
        var savedDescription: String
        @Published var description: String
        @Published var contentAnnotatorScript: URL?
        @Published var contextAnnotators: [ContextAnnotator]
        var folder: URL {
            configurationManager.documentFolderURL.appendingPathComponent(savedDescription)
        }

        init(_ description: String,
             _ configurationManager: ConfigurationManager,
             _ contentAnnotatorScript: URL? = nil,
             _ contextAnnotators: [ContextAnnotator] = []) {
            self.configurationManager = configurationManager
            self.description = description
            savedDescription = description
            self.contentAnnotatorScript = contentAnnotatorScript
            self.contextAnnotators = contextAnnotators
        }
    }

    enum Error: Swift.Error {
        case preferencesError
    }

    init(_ contextAnnotators: [ContextAnnotator] = []) {
        var annotators: [String: ContextAnnotator] = [:]
        for contextAnnotator in contextAnnotators {
            annotators[contextAnnotator.description] = contextAnnotator
        }
        self.contextAnnotators = annotators
    }

    let contextAnnotators: [String: ContextAnnotator]

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

                var contextAnnotators: [ContextAnnotator] = []
                let contextAnnotatorsDeclarations = declaration["contextAnnotators"]
                        as? Array<CFPropertyList> ?? []
                for rawContextAnnotatorDeclaration in contextAnnotatorsDeclarations {
                    if let contextAnnotatorDescription = rawContextAnnotatorDeclaration
                            as? String {
                        if let annotator = self.contextAnnotators[contextAnnotatorDescription] {
                            contextAnnotators.append(annotator)
                        }
                    }
                }

                types.append(DocumentTypeMetadata(description,
                        self,
                        contentAnnotatorURL,
                        contextAnnotators))
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
            "contentAnnotator": contentAnnotatorScript?.path ?? "",
            "contextAnnotators": contextAnnotators.map({ $0.description }) as CFArray
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
                                        scriptPath: $configurationManager.types[index].contentAnnotatorScript,
                                        contextAnnotators: $configurationManager.types[index].contextAnnotators),
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
                    // Workaround for a bug where the NavigationView won't clear the
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


struct DocumentTypeContextAnnotatorsView: NSViewRepresentable {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var contextAnnotators: [ContextAnnotator]

    func makeNSView(context: Context) -> NSTokenField {
        let view = NSTokenField()
        view.delegate = context.coordinator
        view.placeholderString = "Commencez à taper"
        view.stringValue = contextAnnotators.reduce("") { result, annotator in
            result + annotator.description + ","
        }
        view.tokenStyle = .rounded
        view.isBezeled = false
        view.drawsBackground = false

        return view
    }

    func updateNSView(_ nsView: NSTokenField, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTokenFieldDelegate {
        var parent: DocumentTypeContextAnnotatorsView

        init(_ parent: DocumentTypeContextAnnotatorsView) {
            self.parent = parent
        }

        func tokenField(_ tokenField: NSTokenField,
                        completionsForSubstring substring: String,
                        indexOfToken tokenIndex: Int,
                        indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
            parent.configurationManager.contextAnnotators.keys.filter {
                $0.hasPrefix(substring)
            }
        }

        func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
            guard let descriptions = tokens as? [String] else {
                return []
            }
            return parent.configurationManager.contextAnnotators.values.filter {
                descriptions.contains($0.description)
            }
        }

        func tokenField(_ tokenField: NSTokenField,
                        displayStringForRepresentedObject representedObject: Any) -> String? {
            guard let contextAnnotator = representedObject as? ContextAnnotator else {
                return nil
            }
            return contextAnnotator.description
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let tokenField = obj.object as? NSTokenField else {
                return
            }
            let descriptions = tokenField.stringValue.split(separator: ",")
            parent.contextAnnotators = parent.configurationManager.contextAnnotators.values.filter {
                descriptions.contains(Substring($0.description))
            }
            parent.configurationManager.save()
        }
    }
}

/// Removes the focus ring on TextField.
extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get {
            .none
        }
        set {
        }
    }
}

struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var description: String
    @Binding var scriptPath: URL?
    @Binding var contextAnnotators: [ContextAnnotator]
    @State var chooseScriptFile = false

    var body: some View {
        Form {
            GroupBox {
                TextField("Nom du type", text: $description, onCommit: configurationManager.save)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(2)
            }

            GroupBox(label: Text("Script")) {
                HStack {
                    Text(scriptPath?.lastPathComponent ?? "Aucun script associé")
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.head)

                    Spacer()

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
                }.padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
            }

            GroupBox(label: Text("Annotations")) {
                DocumentTypeContextAnnotatorsView(contextAnnotators: $contextAnnotators)
                        .padding(.vertical, 2)
            }
        }.padding(10)
    }
}
