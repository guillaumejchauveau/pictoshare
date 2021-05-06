//
// Created by Guillaume Chauveau on 06/05/2021.
//

import SwiftUI

struct DocumentTypesView: View {
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
                Form {
                    TextField("Nom du type", text: $newTypeDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Spacer(minLength: 50)
                        Button("Annuler") {
                            showNewTypeForm = false
                            newTypeDescription = ""
                        }
                        Button("Créer") {
                            configurationManager.addType(with: newTypeDescription)
                            selection = configurationManager.types.count - 1
                            showNewTypeForm = false
                            newTypeDescription = ""
                        }
                                .keyboardShortcut(.return)
                                .buttonStyle(AccentButtonStyle())
                                .disabled(newTypeDescription.isEmpty)
                    }
                }.padding()
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
            }
                    .buttonStyle(BorderedButtonStyle())
                    .padding([.leading, .bottom, .trailing])
        }.frame(width: 640, height: 360)
    }
}

struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var description: String
    @Binding var contentAnnotatorScript: URL?
    @Binding var copyBeforeScript: Bool
    @Binding var contextAnnotatorNames: Set<String>
    @State private var chooseScriptFile = false
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
                    Toggle("Préserver l'original", isOn: $copyBeforeScript).disabled(contentAnnotatorScript == nil)
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
        }.padding()
    }
}
