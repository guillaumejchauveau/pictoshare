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

    @Published var documentQueue: [URL] = []

    /// Callback used by the ImportationView to indicate witch type was
    /// selected.
    ///
    /// - Parameter index: The index of the selected type, or -1 if canceled.
    /*private func promptDocumentTypeCallback(_ index: Int) {
     window.orderOut(nil)
     guard document != nil else {
     return
     }
     if index >= 0 && index < configurationManager.types.count {
     try! importDocument(document!,
     withType: configurationManager.types[index])
     }
     document = nil
     }*/

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    ///   - document: The Document to import.
    ///   - type: The Type to use for importation.
    /// - Throws: `Error.invalidUUID` if the Type UUID is invalid.
    func importDocument(_ inputUrl: URL, withType type: DocumentType) throws {
        // TODO: Call ContentAnnotator Applescript
        //var contextAnnotations: []
    }
}

struct ImportationView: View {
    @ObservedObject var configurationManager: ConfigurationManager
    @ObservedObject var importationManager: ImportationManager
    @State private var selectedType = 0
    @State private var processedCount = 0
    @State private var progressValue = 0.0


    struct Preview: NSViewRepresentable {
        var importationManager: ImportationManager

        func makeNSView(context: Context) -> NSView {
            let view = QLPreviewView(frame: NSRect(x: 0, y: 0, width: 300, height: 400), style: .normal)!
            if !importationManager.documentQueue.isEmpty {
                view.previewItem = importationManager.documentQueue.first! as QLPreviewItem
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
        }
    }

    var body: some View {
        HStack {
            if !importationManager.documentQueue.isEmpty {
                VStack {
                    Preview(importationManager: importationManager)
                    HStack {
                        ProgressView(value: progressValue)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }.frame(width: 230)
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
        }.padding()
        .frame(height: 300)
        /*.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Ignorer") {
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Importer") {
                }.foregroundColor(Color.accentColor)
            }
        }*/
    }
}

class ImportationWindowController: NSWindowController {
    var importEnabled = false
    
    @IBOutlet var toolbar: NSToolbar!

    @IBAction func `import`(_ sender: Any) {
    }
    @IBOutlet var importButton: NSButton!
    @IBOutlet var ignoreItem: NSToolbarItem!
    override func windowDidLoad() {
        super.windowDidLoad()
        ignoreItem.isEnabled = false
        importButton.isEnabled = false
    }
}

class ImportationViewController: NSViewController {

    override func loadView() {
        view = NSHostingView(rootView: ImportationView(
                              configurationManager: ConfigurationManager.shared,
                              importationManager: ImportationManager.shared))

    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .modalPanel
    }
}
