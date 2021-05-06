//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation
import SwiftUI
import Combine

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
        @Published var copyBeforeScript: Bool
        @Published var contextAnnotatorNames: Set<String>
        private var subscriber: AnyCancellable!

        var contextAnnotators: [ContextAnnotator] {
            contextAnnotatorNames.map {
                configurationManager.contextAnnotators[$0]!
            }
        }

        var folder: URL {
            configurationManager.documentFolderURL.appendingPathComponent(savedDescription)
        }

        init(_ description: String,
             _ configurationManager: ConfigurationManager,
             _ contentAnnotatorScript: URL? = nil,
             _ copyBeforeScript: Bool = true,
             _ contextAnnotatorNames: Set<String> = []) {
            self.configurationManager = configurationManager
            self.description = description
            savedDescription = description
            self.contentAnnotatorScript = contentAnnotatorScript
            self.copyBeforeScript = copyBeforeScript
            self.contextAnnotatorNames = contextAnnotatorNames
            subscriber = self.objectWillChange.sink {
                DispatchQueue.main
                        .asyncAfter(deadline: .now() + .milliseconds(200)) {
                    configurationManager.save(type: self)
                }
            }
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

                let copyBeforeScript = declaration["copyBeforeScript"]
                        as? Bool ?? true

                var contextAnnotators: Set<String> = []
                let contextAnnotatorsDeclarations = declaration["contextAnnotators"]
                        as? Array<CFPropertyList> ?? []
                for rawContextAnnotatorDeclaration in contextAnnotatorsDeclarations {
                    if let contextAnnotatorDescription = rawContextAnnotatorDeclaration
                            as? String {
                        if self.contextAnnotators.keys.contains(contextAnnotatorDescription) {
                            contextAnnotators.insert(contextAnnotatorDescription)
                        }
                    }
                }

                types.append(DocumentTypeMetadata(description,
                        self,
                        contentAnnotatorURL,
                        copyBeforeScript,
                        contextAnnotators))
            } catch {
                continue
            }
        }
    }

    private func updateTypeFolder(_ type: DocumentTypeMetadata) {
        let newUrl = documentFolderURL.appendingPathComponent(type.description)
        let oldUrl = documentFolderURL.appendingPathComponent(type.savedDescription)
        if !FileManager.default.fileExists(atPath: oldUrl.path) {
            try! FileManager.default.createDirectory(at: newUrl, withIntermediateDirectories: true)
        } else {
            if type.savedDescription != type.description {
                do {
                    try FileManager.default.moveItem(at: oldUrl, to: newUrl)
                    type.savedDescription = type.description
                } catch {
                    type.description = type.savedDescription
                }
            }
        }
    }

    /// Saves the given Document Type to persistent storage and manages corresponding folders.
    /// Currently as multiple failing situations:
    /// - a file exists with the name of the document type;
    /// - the name of the document type contains forbidden characters for paths;
    /// - two document types have the same name.
    func save(type: DocumentTypeMetadata) {
        updateTypeFolder(type)

        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    func saveAll() {
        for type in types {
            updateTypeFolder(type)
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
            "copyBeforeScript": copyBeforeScript,
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
                List(configurationManager.types.indices, id: \.self) { index in
                    NavigationLink(
                            destination: DocumentTypeView(
                                    description: $configurationManager.types[index].description,
                                    contentAnnotatorScript: $configurationManager.types[index].contentAnnotatorScript,
                                    copyBeforeScript: $configurationManager.types[index].copyBeforeScript,
                                    contextAnnotatorNames: $configurationManager.types[index].contextAnnotatorNames,
                                    editingDescription: configurationManager.types[index].description),
                            tag: index,
                            selection: $selection) {
                        Text(configurationManager.types[index].description)
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
                        if index < configurationManager.types.count {
                            configurationManager.types.remove(at: index)
                        }
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
        view.placeholderString = "Selectionnez parmis les annotations disponibles"
        view.tokenStyle = .rounded
        view.isBezeled = false
        view.drawsBackground = false
        updateString(of: view)

        return view
    }

    func updateNSView(_ nsView: NSTokenField, context: Context) {
        //updateString(of: nsView)
    }

    private func updateString(of token: NSTokenField) {
        token.stringValue = contextAnnotators.reduce("") {
            $0 + $1.description + ","
        }
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
            selectedIndex?.pointee = -1
            return parent.configurationManager.contextAnnotators.keys.filter {
                $0.simplified().hasPrefix(substring.simplified())
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tokenField = obj.object as? NSTokenField else {
                return
            }
            let descriptions = tokenField.stringValue.split(separator: ",")
            parent.contextAnnotators = parent.configurationManager.contextAnnotators.values.filter {
                descriptions.contains(Substring($0.description))
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            //parent.configurationManager.save()
        }
    }
}

struct DocumentTypeAvailableContextAnnotatorsView: NSViewRepresentable {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var selectedAnnotators: [ContextAnnotator]

    func makeNSView(context: Context) -> NSTokenField {
        let view = NSTokenField()
        view.delegate = context.coordinator
        view.tokenStyle = .rounded
        view.isBezeled = false
        view.drawsBackground = false
        view.isVerticalContentSizeConstraintActive = false
        view.isSelectable = true
        view.isEditable = false
        updateString(of: view)

        return view
    }

    func updateNSView(_ nsView: NSTokenField, context: Context) {
        updateString(of: nsView)
    }

    private func updateString(of token: NSTokenField) {
        let selectedDescriptions = selectedAnnotators.map {
            $0.description
        }
        token.stringValue = configurationManager.contextAnnotators.keys.filter {
            !selectedDescriptions.contains($0.description)
        }.reduce("") {
            $0 + $1.description + ","
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTokenFieldDelegate {
        var parent: DocumentTypeAvailableContextAnnotatorsView

        init(_ parent: DocumentTypeAvailableContextAnnotatorsView) {
            self.parent = parent
        }

        func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
            guard let descriptions = tokens as? [String] else {
                return []
            }
            return parent.configurationManager.contextAnnotators.keys.filter {
                descriptions.contains($0) && !parent.selectedAnnotators.map({ $0.description }).contains($0)
            }
        }
    }
}


struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var description: String
    @Binding var contentAnnotatorScript: URL?
    @Binding var copyBeforeScript: Bool
    @Binding var contextAnnotatorNames: Set<String>
    @State var chooseScriptFile = false
    @State var editingDescription: String

    private func validateDescription() {
        description = editingDescription
    }

    var body: some View {
        Form {
            GroupBox(label: Text("Nom")) {
                HStack {
                    TextField("", text: $editingDescription, onCommit: validateDescription)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(2)
                    Spacer()
                    Button(action: validateDescription) {
                        Image(systemName: "checkmark")
                    }.disabled(description == editingDescription)
                }
            }

            GroupBox(label: Text("Script")) {
                VStack(alignment: .leading) {
                    HStack {
                        if let scriptName = contentAnnotatorScript?.lastPathComponent {
                            Text(scriptName)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.head)
                        } else {
                            Text("Aucun script associé")
                                    .font(.italic(.system(size: 12))())
                                    .foregroundColor(.gray)
                        }

                        Spacer()

                        /// Button to load an applescript.
                        Button(action: {
                            chooseScriptFile = true
                        }) {
                            Image(systemName: "folder")
                        }.fileImporter(isPresented: $chooseScriptFile, allowedContentTypes: [.osaScript]) { result in
                            contentAnnotatorScript = try? result.get()
                        }

                        /// Button to withdraw the current selected type's applescript
                        Button(action: {
                            contentAnnotatorScript = nil
                            copyBeforeScript = true
                        }) {
                            Image(systemName: "trash")
                        }.disabled(contentAnnotatorScript == nil)
                    }.padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                    Toggle("Faire une copie", isOn: $copyBeforeScript).disabled(contentAnnotatorScript == nil)
                }
            }

            GroupBox(label: Text("Annotations")) {
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(configurationManager.contextAnnotators.values
                                .sorted(by: { $0.description > $1.description }), id: \.description) { annotator in
                            NamesSetToggleView(names: $contextAnnotatorNames,
                                    description: annotator.description,
                                    state: contextAnnotatorNames.contains(annotator.description))
                        }
                    }
                    Spacer()
                }
            }
        }.padding(10)
    }
}

struct NamesSetToggleView: View {
    @Binding var names: Set<String>
    var description: String
    @State var state: Bool

    var body: some View {
        Toggle(description, isOn: Binding<Bool>(
                get: {
                    state
                },
                set: {
                    state = $0
                    if state {
                        names.insert(description)
                    } else {
                        names.remove(description)
                    }
                }
        ))
    }
}
