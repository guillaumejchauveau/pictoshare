//
// Created by Guillaume Chauveau on 12/04/2021.
//

import SwiftUI

struct ContinuityCameraButton: NSViewRepresentable {
    class Responder: NSResponder, NSServicesMenuRequestor {
        var configurationManager: ConfigurationManager!

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
                //try? imageData.write(to: configurationManager.documentFolderURL!.appendingPathComponent("test.tiff"))
                return true
            }
            return false
        }

        @objc func showMenu(_ sender: NSView) {
            guard let event = NSApplication.shared.currentEvent else { return }
            // AppKit uses the Responder Chain to figure out where to insert the Continuity Camera menu items.
            // So making ourselves `firstResponder` here is important.
            sender.window?.makeFirstResponder(self)
            NSMenu.popUpContextMenu(sender.menu!, with: event, for: sender)
        }
    }

    @EnvironmentObject var configurationManager: ConfigurationManager
    @Binding var showMenu: Bool
    private let responder = Responder()

    func makeNSView(context: Context) -> NSView {
        responder.configurationManager = configurationManager
        let view = NSButton(title: "Prendre une photo", target: responder, action: #selector(responder.showMenu))
        view.menu = NSMenu()
        view.menu!.addItem(NSMenuItem(title: "Aucun appareil disponible", action: nil, keyEquivalent: ""))
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if (showMenu) {
            showMenu = false
        }
    }
}
