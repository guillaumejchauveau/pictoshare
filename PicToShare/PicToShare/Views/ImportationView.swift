import SwiftUI
import Quartz


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


struct ImportationView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager
    @State private var selectedType = 0

    var body: some View {
        VStack {
            FilePreviewView()
            HStack {
                Text(importationManager.queueHead?.lastPathComponent ?? "")
            }
        }
        VStack {
            GroupBox {
                ScrollView {
                    Spacer()
                    Picker("", selection: $selectedType) {
                        ForEach(configurationManager.types.indices,
                                id: \.self) { index in
                            Text(configurationManager.types[index].description)
                                    .frame(width: 200)
                        }
                    }.pickerStyle(RadioGroupPickerStyle())
                }
            }
            HStack {
                Button("ignore") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    _ = importationManager.popQueueHead()
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
                }.buttonStyle(AccentButtonStyle())
            }
        }
    }
}
