//
//  ContextsView.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 07/05/2021.
//

import SwiftUI


struct ContextsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    var body: some View {
        VStack(alignment: .leading) {
            ListSettingsView(items: $configurationManager.contexts,
                             add: configurationManager.addContext,
                             remove: configurationManager.removeContext) { index in
                ContextView(
                    description: $configurationManager.contexts[index].description,
                    contextAnnotatorNames: $configurationManager.contexts[index].contextAnnotatorNames,
                    documentIntegratorNames: $configurationManager.contexts[index].documentIntegratorNames,
                    editingDescription: configurationManager.contexts[index].description)
            }
        }.frame(width: 640, height: 360)
    }
}


struct ContextView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var description: String
    @Binding var contextAnnotatorNames: Set<String>
    @Binding var documentIntegratorNames: Set<String>
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

            NamesSetGroupView(label: Text("Annotations"),
                              availableNames: $configurationManager.contextAnnotators,
                              selectedNames: $contextAnnotatorNames)

            NamesSetGroupView(label: Text("Intégrations"),
                              availableNames: $configurationManager.documentIntegrators,
                              selectedNames: $documentIntegratorNames)
        }.padding()
    }
}

