//
// Created by Guillaume Chauveau on 06/05/2021.
//

import SwiftUI

struct DocumentTypesView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    struct Landing: View {
        var body: some View {
            ZStack {
                Image(systemName: "questionmark.circle").imageScale(.large)
                        .font(.system(size: 30))
                        .offset(y: -80)
                Text("""
                     Créez des types de documents pour adapter les paramètres d'importation.
                     Vous pouvez spécifier un script pour transformer le document avant de l'importer.
                     """).font(.system(size: 16, weight: .light)).lineSpacing(5)
            }.frame(width: 400)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            ListSettingsView(items: $configurationManager.types,
                    add: configurationManager.addType,
                    remove: configurationManager.removeType,
                    landing: Landing()) { index in
                DocumentTypeView(
                        description: $configurationManager.types[index].description,
                        documentProcessingScript: $configurationManager.types[index].documentProcessorScript,
                        copyBeforeProcessing: $configurationManager.types[index].copyBeforeProcessing,
                        removeOriginalOnProcessingByproduct: $configurationManager.types[index].removeOriginalOnProcessingByproduct,
                        documentAnnotators: $configurationManager.types[index].documentAnnotators,
                        documentIntegrators: $configurationManager.types[index].documentIntegrators,
                        editingDescription: configurationManager.types[index].description)
            }
        }
    }
}

struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    @Binding var description: String
    @Binding var documentProcessingScript: URL?
    @Binding var copyBeforeProcessing: Bool
    @Binding var removeOriginalOnProcessingByproduct: Bool
    @Binding var documentAnnotators: Set<HashableDocumentAnnotator>
    @Binding var documentIntegrators: Set<HashableDocumentIntegrator>

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

            SetGroupView(label: Text("Annotations"),
                    available: $configurationManager.documentAnnotators,
                    selected: $documentAnnotators)

            SetGroupView(label: Text("Intégrations"),
                    available: $configurationManager.documentIntegrators,
                    selected: $documentIntegrators)
        }.padding()
    }
}
