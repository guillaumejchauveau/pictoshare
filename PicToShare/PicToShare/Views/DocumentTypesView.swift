//
// Created by Guillaume Chauveau on 06/05/2021.
//

import SwiftUI

struct DocumentTypesView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    var body: some View {
        VStack(alignment: .leading) {
            ListSettingsView(items: $configurationManager.types,
                             add: configurationManager.addType,
                             remove: configurationManager.removeType) { index in
                DocumentTypeView(
                    description: $configurationManager.types[index].description,
                    contentAnnotatorScript: $configurationManager.types[index].contentAnnotatorScript,
                    copyBeforeScript: $configurationManager.types[index].copyBeforeScript,
                    contextAnnotatorNames: $configurationManager.types[index].contextAnnotatorNames,
                    documentIntegratorNames: $configurationManager.types[index].documentIntegratorNames,
                    editingDescription: configurationManager.types[index].description)
            }
        }.frame(width: 640, height: 360)
    }
}

struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var description: String
    @Binding var contentAnnotatorScript: URL?
    @Binding var copyBeforeScript: Bool
    @Binding var contextAnnotatorNames: Set<String>
    @Binding var documentIntegratorNames: Set<String>
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
                                    .font(.system(size: 12))
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

            NamesSetGroupView(label: Text("Annotations"),
                              availableNames: $configurationManager.contextAnnotators,
                              selectedNames: $contextAnnotatorNames)

            NamesSetGroupView(label: Text("Intégrations"),
                              availableNames: $configurationManager.documentIntegrators,
                              selectedNames: $documentIntegratorNames)
        }.padding()
    }
}
