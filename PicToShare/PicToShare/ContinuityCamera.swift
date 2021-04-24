//
// Created by Guillaume Chauveau on 12/04/2021.
//

import SwiftUI


class ContinuityCameraDocumentSource {
    private let configurationManager: ConfigurationManager

    init(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    func createTiffDocument(from data: Data) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            try? data.write(to: configurationManager.documentFolderURL!.appendingPathComponent("\(dateFormatter.string(from: Date())).tiff"))
    }

    func createPDFDocument(from data: Data) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            try? data.write(to: configurationManager.documentFolderURL!.appendingPathComponent("\(dateFormatter.string(from: Date())).pdf"))
    }
}

final class ContinuityCameraController: NSViewController, NSServicesMenuRequestor, NSViewControllerRepresentable {
    var source: ContinuityCameraDocumentSource!

    override func loadView() {
        let button = NSButton(title: "", target: self, action: #selector(showMenu))
        button.isTransparent = true
        button.menu = NSMenu()
        view = button
    }

    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        if let pasteboardType = returnType,
           // Service is image related.
           NSImage.imageTypes.contains(pasteboardType.rawValue) {
            return self  // This object can receive image data.
        } else {
            // Let objects in the responder chain handle the message.
            return super.validRequestor(forSendType: sendType, returnType: returnType)
        }
    }

    func readSelection(from pasteboard: NSPasteboard) -> Bool {
        if let imageData = pasteboard.data(forType: .tiff) {
            source.createTiffDocument(from: imageData)
            return true
        }
        if let pdfData = pasteboard.data(forType: .pdf) {
            source.createPDFDocument(from: pdfData)
            return true
        }
        return false
    }

    @objc func showMenu(_ sender: NSButton) {
        guard let menu = view.menu else {
            return
        }
        guard let event = NSApplication.shared.currentEvent else {
            return
        }

        // AppKit uses the Responder Chain to figure out where to insert the Continuity Camera menu items.
        // So making ourselves `firstResponder` here is important.
        view.window!.makeFirstResponder(self)
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        self
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
    }
}
