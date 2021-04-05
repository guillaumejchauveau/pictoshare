//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import SwiftUI
import Quartz

/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    static let shared = ImportationManager()

    private var documentQueue: [URL] = []
    let importationWindowURL: URL! = URL(string: "pictoshare2://import")

    var queueHead: URL? {
        documentQueue.first
    }

    var queueCount: Int {
        documentQueue.count
    }

    func queue(document url: URL) {
        documentQueue.append(url)
        objectWillChange.send()
        NSWorkspace.shared.open(importationWindowURL)
    }

    func queue<S>(documents urls: S) where S.Element == URL, S: Sequence {
        documentQueue.append(contentsOf: urls)
        objectWillChange.send()
        NSWorkspace.shared.open(importationWindowURL)
    }

    func popQueueHead() {
        documentQueue.removeFirst()
        objectWillChange.send()
    }

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    ///   - document: The Document to import.
    ///   - type: The Type to use for importation.
    /// - Throws: `Error.invalidUUID` if the Type UUID is invalid.
    func importDocument(_ inputUrl: URL, withType type: DocumentType) throws {
        // TODO: Call ContentAnnotator Applescript
        //var contextAnnotations: []
        print("import")
    }
}

struct ImportationView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager
    @State private var selectedType = 0
    @State private var processedCount = 0

    struct Preview: NSViewRepresentable {
        @ObservedObject var importationManager: ImportationManager

        func makeNSView(context: Context) -> QLPreviewView {
            let view = QLPreviewView(
                    frame: NSRect(x: 0, y: 0, width: 200, height: 250),
                    style: .compact)!

            // Hack to set the window level.
            DispatchQueue.main.async {
                view.window?.level = .modalPanel
            }

            view.previewItem = importationManager.queueHead as QLPreviewItem?
            return view
        }

        func updateNSView(_ nsView: QLPreviewView, context: Context) {
            nsView.previewItem = importationManager.queueHead as QLPreviewItem?
            if importationManager.queueHead == nil {
                nsView.window?.close()
            }
        }
    }

    var body: some View {
        HStack {
            if importationManager.queueHead != nil {
                VStack {
                    Preview(importationManager: importationManager)
                    HStack {
                        Text("\(processedCount + 1) sur \(processedCount + importationManager.queueCount)")
                    }
                }.frame(width: 230)
                        .padding(.trailing)
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
                }.frame(width: 230)
            } else {
                VStack {
                    Text("Rien à importer").font(.largeTitle)
                }.frame(width: 460)
            }
        }.padding().frame(height: 300).toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Ignorer") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    importationManager.popQueueHead()
                    processedCount += 1
                }.disabled(importationManager.queueHead == nil)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Importer") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    guard selectedType < configurationManager.types.count &&
                                  selectedType >= 0 else {
                        return
                    }
                    try! importationManager.importDocument(
                            importationManager.queueHead!,
                            withType: configurationManager.types[selectedType])
                    importationManager.popQueueHead()
                    processedCount += 1
                }.foregroundColor(Color.accentColor)
                        .disabled(importationManager.queueHead == nil)
            }
        }
    }
}
