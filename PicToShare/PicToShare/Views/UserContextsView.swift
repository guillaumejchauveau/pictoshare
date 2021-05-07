//
//  ContextsView.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 07/05/2021.
//

import SwiftUI


struct UserContextsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    var body: some View {
        VStack(alignment: .leading) {
            ListSettingsView(items: $configurationManager.contexts,
                             add: configurationManager.addContext,
                             remove: configurationManager.removeContext) { index in
                UserContextView(
                    description: $configurationManager.contexts[index].description,
                    documentAnnotatorNames: $configurationManager.contexts[index].documentAnnotatorNames,
                    documentIntegratorNames: $configurationManager.contexts[index].documentIntegratorNames,
                    editingDescription: configurationManager.contexts[index].description)
            }
        }
    }
}


struct UserContextView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    @Binding var description: String
    @Binding var documentAnnotatorNames: Set<String>
    @Binding var documentIntegratorNames: Set<String>

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

            NamesSetGroupView(label: Text("Annotations"),
                              availableNames: $configurationManager.documentAnnotators,
                              selectedNames: $documentAnnotatorNames)

            NamesSetGroupView(label: Text("Intégrations"),
                              availableNames: $configurationManager.documentIntegrators,
                              selectedNames: $documentIntegratorNames)
        }.padding()
    }
}

