import SwiftUI

/// View for editing Document Types in the settings.
struct DocumentTypesView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    struct Landing: View {
        var body: some View {
            ZStack {
                Image(systemName: "questionmark.circle").imageScale(.large)
                        .font(.system(size: 30))
                        .offset(y: -80)
                Text("pts.settings.types.landing")
                        .font(.system(size: 16, weight: .light)).lineSpacing(5)
            }.frame(width: 400)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Uses a custom View to make a Navigation View with all the Types.
            ListSettingsView(items: $configurationManager.types,
                    add: configurationManager.addType,
                    remove: configurationManager.removeType,
                    landing: Landing()) { index in
                DocumentTypeView(
                        description: $configurationManager.types[index].description,
                        documentProcessorScript: $configurationManager.types[index].documentProcessorScript,
                        copyBeforeProcessing: $configurationManager.types[index].copyBeforeProcessing,
                        removeOriginalOnProcessingByproduct: $configurationManager.types[index].removeOriginalOnProcessingByproduct,
                        documentAnnotators: $configurationManager.types[index].documentAnnotators,
                        documentIntegrators: $configurationManager.types[index].documentIntegrators,
                        editingDescription: configurationManager.types[index].description)
            }
        }
    }
}

/// A View for editing a Document Type.
struct DocumentTypeView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    // Tried to store the Type itself as an ObservedObject, doesn't work, tried
    // to move the bindings in a constructor, doesn't work either, so we're
    // stuck with a ton of lines.
    @Binding var description: String
    @Binding var documentProcessorScript: URL?
    @Binding var copyBeforeProcessing: Bool?
    @Binding var removeOriginalOnProcessingByproduct: Bool?
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

            GroupBox(label: Text("pts.processingScript")) {
                VStack(alignment: .leading) {
                    HStack {
                        if let scriptName = documentProcessorScript?.lastPathComponent {
                            Text(scriptName)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.head)
                        } else {
                            Text("pts.settings.types.noProcessingScript")
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
                            documentProcessorScript = try? result.get()
                        }

                        Button(action: {
                            documentProcessorScript = nil
                            copyBeforeProcessing = true
                            removeOriginalOnProcessingByproduct = false
                        }) {
                            Image(systemName: "trash")
                        }.disabled(documentProcessorScript == nil)
                    }.padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))

                    Toggle("pts.settings.types.copyBeforeProcessing",
                            isOn: Binding<Bool>($copyBeforeProcessing)!)
                            .disabled(documentProcessorScript == nil)
                    Toggle("pts.settings.types.removeOriginalOnProcessingByproduct",
                            isOn: Binding<Bool>($removeOriginalOnProcessingByproduct)!)
                            .disabled(documentProcessorScript == nil)
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
