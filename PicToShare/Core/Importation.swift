//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation
import SwiftUI


/// Object responsible of the Importation process.
class ImportationManager {

    struct ContentView: View {
        @State var selected = 0
        private let types: [String]
        private let manager: ImportationManager

        init(_ types: [String], _ manager: ImportationManager) {
            self.types = types
            self.manager = manager
        }

        var body: some View {
            VStack {
                GroupBox {
                    ScrollView {
                        Picker("", selection: $selected) {
                            ForEach(0..<types.count, content: { index in
                                Text(types[index])
                            })
                        }
                                .pickerStyle(RadioGroupPickerStyle())
                    }
                }
                        .padding()
                Text("Type selectionné: \(types[selected])")
                Button("OK", action: { manager.ok(selected) })
                        .padding()
            }
                    .frame(width: 300, height: 300, alignment: .center)
        }
    }

    // Fontion du bouton OK qui enregistre et transmet le choix de type
    fileprivate func ok(_ index: Int) {
        guard document != nil else {
            return
        }
        guard index < configurationManager!.types.count else {
            return
        }
        try! importDocument(document!, withType: configurationManager!.types[index])
        document = nil
    }

    private var configurationManager: ConfigurationManager?

    private let panel: NSPanel
    private var document: AnyObject?

    init() {
        // Create the window and set the content view.
        panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered, defer: true)
        panel.center()
        panel.setFrameAutosaveName("Choix du type")
    }

    func setConfigurationManager(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    /// Asks the User for a Document Type for importation.
    ///
    /// - Parameter document: The Document to import.
    func promptDocumentType(_ document: AnyObject) {
        guard self.document == nil else {
            return
        }
        self.document = document
        let contentView = ContentView(
                configurationManager!.types.map {
                    $0.description
                }, self
        )
        panel.contentView = NSHostingView(rootView: contentView)
        //panel.orderFront(nil)
        //ok(0)
    }

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    ///   - document: The Document to import.
    ///   - type: The Type to use for importation.
    /// - Throws: `Error.invalidUUID` if the Type UUID is invalid.
    func importDocument(_ document: AnyObject, withType type: DocumentType) throws {
        for annotator in type.annotators {
            try annotator.annotate(document: document)
        }

        // TODO: Complete exportation process.
        try type.exporter.export(document: document)
        // TODO: Complete integration process.
    }
}

