//
// Created by Guillaume Chauveau on 12/04/2021.
//

import SwiftUI


class ContinuityCameraController: NSViewController, NSServicesMenuRequestor {
    var configurationManager: ConfigurationManager!
    var importationManager: ImportationManager!

    override func loadView() {
        let button = NSButton(title: "", target: self, action: #selector(showMenu))
        button.isTransparent = true
        button.menu = NSMenu()
        button.menu!.addItem(NSMenuItem(title: "Aucun appareil disponible", action: nil, keyEquivalent: ""))
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        var data: Data?
        var fileName = dateFormatter.string(from: Date())

        if data == nil {
            data = pasteboard.data(forType: .tiff)
            fileName = "\(fileName).tif"
        }
        if data == nil {
            data = pasteboard.data(forType: .pdf)
            fileName = "\(fileName).pdf"
        }

        if data == nil {
            return false
        }
        let fileUrl = configurationManager.documentFolderURL.appendingPathComponent(fileName)
        do {
            try data!.write(to: fileUrl)
        } catch {
            NotificationManager.notifyUser(
                    "Erreur avec Continuity Camera",
                    "PicToShare n'a pas pu enregistrer le fichier provenant de Continuity",
                    "PTS-ContinuityCamera")
        }
        importationManager.queue(document: fileUrl)
        return true
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
        view.window?.makeFirstResponder(self)
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }
}

struct ContinuityCameraButton: NSViewControllerRepresentable {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager

    func makeNSViewController(context: Context) -> ContinuityCameraController {
        let controller = ContinuityCameraController()
        controller.configurationManager = configurationManager
        controller.importationManager = importationManager
        return controller
    }

    func updateNSViewController(_ nsViewController: ContinuityCameraController, context: Context) {
    }
}
