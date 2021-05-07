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
                    documentProcessingScript: $configurationManager.types[index].documentProcessorScript,
                    copyBeforeProcessing: $configurationManager.types[index].copyBeforeProcessing,
                    removeOriginalOnProcessingByproduct: $configurationManager.types[index].removeOriginalOnProcessingByproduct,
                    documentAnnotatorNames: $configurationManager.types[index].documentAnnotatorNames,
                    documentIntegratorNames: $configurationManager.types[index].documentIntegratorNames,
                    editingDescription: configurationManager.types[index].description)
            }
        }.frame(width: 640, height: 360)
    }
}

struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    @Binding var description: String
    @Binding var documentProcessingScript: URL?
    @Binding var copyBeforeProcessing: Bool
    @Binding var removeOriginalOnProcessingByproduct: Bool
    @Binding var documentAnnotatorNames: Set<String>
    @Binding var documentIntegratorNames: Set<String>

    @State private var chooseScriptFile = false
    @State var editingDescription: String

    private func validateDescription() {
        if editingDescription.isEmpty {
            NSSound.beep()
            return
        }
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

            GroupBox(label: Text("Script de traitement")) {
                VStack(alignment: .leading) {
                    HStack {
                        if let scriptName = documentProcessingScript?.lastPathComponent {
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

                        Button(action: {
                            chooseScriptFile = true
                        }) {
                            Image(systemName: "folder")
                        }.fileImporter(isPresented: $chooseScriptFile,
                                       allowedContentTypes: [.osaScript]) { result in
                            documentProcessingScript = try? result.get()
                        }

                        Button(action: {
                            documentProcessingScript = nil
                            copyBeforeProcessing = true
                            removeOriginalOnProcessingByproduct = false
                        }) {
                            Image(systemName: "trash")
                        }.disabled(documentProcessingScript == nil)
                    }.padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))

                    Toggle("Préserver une copie de l'original",
                           isOn: $copyBeforeProcessing)
                        .disabled(documentProcessingScript == nil)
                    Toggle("Si le script crée de nouveaux fichiers, supprimer l'original",
                        isOn: $removeOriginalOnProcessingByproduct)
                        .disabled(documentProcessingScript == nil)
                }
            }

            NamesSetGroupView(label: Text("Annotations"),
                              availableNames: $configurationManager.documentAnnotators,
                              selectedNames: $documentAnnotatorNames)

            NamesSetGroupView(label: Text("Intégrations"),
                              availableNames: $configurationManager.documentIntegrators,
                              selectedNames: $documentIntegratorNames)
        }.padding()
    }
}
