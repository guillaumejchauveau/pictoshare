import SwiftUI


struct UserContextsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    struct Landing: View {
        var body: some View {
            ZStack {
                Image(systemName: "questionmark.circle").imageScale(.large)
                        .font(.system(size: 30))
                        .offset(y: -80)
                Text("pts.settings.userContexts.landing")
                        .font(.system(size: 16, weight: .light)).lineSpacing(5)
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
                        documentAnnotators: $configurationManager.contexts[index].documentAnnotators,
                        documentIntegrators: $configurationManager.contexts[index].documentIntegrators,
                        editingDescription: configurationManager.contexts[index].description)
            }
        }
    }
}


struct UserContextView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    @Binding var description: String
    @Binding var documentAnnotators: Set<HashableDocumentAnnotator>
    @Binding var documentIntegrators: Set<HashableDocumentIntegrator>

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
            GroupBox(label: Text("name")) {
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

            GroupBox(label: Text("pts.annotations")) {
                HStack {
                    SetOptionsView(
                            options: $configurationManager.documentAnnotators,
                            selected: $documentAnnotators)
                    Spacer()
                }
            }

            GroupBox(label: Text("pts.integrations")) {
                HStack {
                    SetOptionsView(
                            options: $configurationManager.documentIntegrators,
                            selected: $documentIntegrators)
                    Spacer()
                }
            }
        }.padding()
    }
}

