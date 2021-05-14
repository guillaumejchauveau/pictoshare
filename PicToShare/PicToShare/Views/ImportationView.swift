import SwiftUI
import Quartz

/// SwiftUI View wrapper for QLPreviewView
struct FilePreviewView: NSViewRepresentable {
    @EnvironmentObject var importationManager: ImportationManager

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(
                frame: NSRect(x: 0, y: 0, width: 230, height: 250),
                style: .compact)!

        view.previewItem = importationManager.queueHead as QLPreviewItem?
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = importationManager.queueHead as QLPreviewItem?
    }
}

/// View for selecting a Document Type on importation.
struct ImportationView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager
    @State private var selectedType = 0
    @State private var showConfirmIgnore = false

    var body: some View {
        VStack {
            FilePreviewView()
            Text(importationManager.queueHead?.lastPathComponent ?? "")
        }
        VStack {
            GroupBox {
                ScrollView {
                    Picker("", selection: $selectedType) {
                        ForEach(configurationManager.types.indices,
                                id: \.self) { index in
                            HStack {
                                Text(configurationManager.types[index].description)
                                Spacer()
                            }
                        }
                    }
                            .pickerStyle(RadioGroupPickerStyle())
                            .frame(width: 200)
                            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                }
            }
            HStack {
                Button("ignore") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    showConfirmIgnore = true
                }
                        .keyboardShortcut(.cancelAction)
                        .alert(isPresented: $showConfirmIgnore) {
                            Alert(
                                    title: Text("pts.import.ignore.confirm.title"),
                                    message: Text("pts.import.ignore.confirm.message"),
                                    primaryButton: .destructive(Text("ignore")) {
                                        _ = importationManager.popQueueHead()
                                    },
                                    secondaryButton: .cancel(Text("return")))
                        }
                Button("import") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    guard selectedType < configurationManager.types.count &&
                                  selectedType >= 0 else {
                        return
                    }
                    let type = configurationManager.types[selectedType]
                    let context = configurationManager.currentUserContext
                    var document = importationManager.popQueueHead()!
                    let documentFolder = document.deletingLastPathComponent()

                    // Rename Continuity Camera document before importing.
                    if documentFolder == configurationManager.continuityFolderURL {
                        let newDocument = documentFolder.appendingPathComponent(
                                type.description + "_" + (context?.description ?? "") +
                                        "_" + document.lastPathComponent)
                        // Do-catch block to change the document URL only if the move
                        // succeeded.
                        do {
                            try FileManager.default.moveItem(at: document, to: newDocument)
                            document = newDocument
                        } catch {

                        }
                    }

                    importationManager.importDocument(document, with: type, context)
                }
                        .keyboardShortcut(.defaultAction)
                        .disabled(selectedType >= configurationManager.types.count)
            }
        }
    }
}
