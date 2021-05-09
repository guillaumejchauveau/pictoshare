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
    @State private var processedCount = 0

    var body: some View {
        VStack {
            FilePreviewView()
            HStack {
                Text("\(processedCount + 1) sur \(processedCount + importationManager.queueCount)")
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
                Button("Ignorer") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    importationManager.popQueueHead()
                    processedCount += 1
                }
                Button("Importer") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    guard selectedType < configurationManager.types.count &&
                                  selectedType >= 0 else {
                        return
                    }
                    let type = configurationManager.types[selectedType]
                    let context = configurationManager.currentUserContext
                    importationManager.importDocument(with: ImportationMetadata(
                            url: importationManager.queueHead!,
                            type: type,
                            annotators: type.documentAnnotators
                                    .union(context?.documentAnnotators ?? []),
                            integrators: type.documentIntegrators
                                    .union(context?.documentIntegrators ?? [])))
                    importationManager.popQueueHead()
                    processedCount += 1
                }.buttonStyle(AccentButtonStyle())
            }
        }
    }
}
