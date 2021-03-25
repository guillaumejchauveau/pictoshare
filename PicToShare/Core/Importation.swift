//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import SwiftUI

private struct ImportationView: View {
    @State var selected = 0
    private let types: [String]
    private let callback: (Int) -> ()

    init(_ types: [String], _ callback: @escaping (Int) -> ()) {
        self.types = types
        self.callback = callback
    }

    var body: some View {
        VStack {
            GroupBox {
                ScrollView {
                    Picker("", selection: $selected) {
                        ForEach(0..<types.count) { index in
                            Text(types[index]).frame(width: 200)
                        }
                    }.pickerStyle(RadioGroupPickerStyle())
                }
            }
            Spacer()
            HStack {
                Button("Annuler") {
                    callback(-1)
                }
                // Manually style this button just to set it blue.
                Button("Importer") {
                    callback(selected)
                }
                        .body.padding(EdgeInsets(top: 2,
                                leading: 7,
                                bottom: 2,
                                trailing: 7))
                        .background(Color.accentColor)
                        .buttonStyle(PlainButtonStyle())
                        .cornerRadius(5)
            }
        }.padding()
    }
}

/// Object responsible of the Importation process.
class ImportationManager {
    private var configurationManager: ConfigurationManager!

    private let window: NSWindow
    private var document: URL?

    init() {
        window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .fullSizeContentView],
                backing: .buffered, defer: true)
        window.center()
        window.title = "PicToShare - Importer un document"
        window.level = NSWindow.Level.modalPanel
    }

    func setConfigurationManager(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    /// Asks the User for a Document Type for importation.
    ///
    /// - Parameter document: The Document to import.
    func promptDocumentType(_ document: URL) {
        guard self.document == nil else {
            return
        }
        self.document = document
        window.contentView = NSHostingView(rootView: ImportationView(
                configurationManager.types.map {
                    $0.description
                }, promptDocumentTypeCallback))
        window.makeKeyAndOrderFront(nil)
    }

    /// Callback used by the ImportationView to indicate witch type was
    /// selected.
    ///
    /// - Parameter index: The index of the selected type, or -1 if canceled.
    private func promptDocumentTypeCallback(_ index: Int) {
        window.orderOut(nil)
        guard document != nil else {
            return
        }
        if index >= 0 && index < configurationManager.types.count {
            try! importDocument(document!,
                    withType: configurationManager.types[index])
        }
        document = nil
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
    }
}

struct ImportationManager_Previews: PreviewProvider {
    static var previews: some View {
        ImportationView(["Carte de visite", "Image", "Document"], { _ in })
    }
}

