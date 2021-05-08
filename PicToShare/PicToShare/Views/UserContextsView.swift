//
//  ContextsView.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 07/05/2021.
//

import SwiftUI


struct UserContextsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    struct Landing: View {
        var body: some View {
            ZStack {
                Image(systemName: "questionmark.circle").imageScale(.large)
                    .font(.system(size: 30))
                    .offset(y: -80)
                Text("""
                Créez des contextes pour adapter l'importation selon votre activité.
                Les annotations et intégrations configurées seront ajoutées à celles du type de document.
                """).font(.system(size: 16, weight: .light)).lineSpacing(5)
            }.frame(width: 400)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            ListSettingsView(items: $configurationManager.contexts,
                             add: configurationManager.addContext,
                             remove: configurationManager.removeContext,
                             landing: Landing()) { index in
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

