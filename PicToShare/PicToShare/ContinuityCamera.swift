import SwiftUI

extension PicToShareError {
    static let continuity = PicToShareError(type: "pts.error.continuity")
}

/// View Controller for a NSButton opening a NSMenu for Continuity Camera
/// service.
/// Adaptation of https://thomas.zoechling.me/journal/2018/10/Continuity.html.
class ContinuityCameraController: NSViewController, NSServicesMenuRequestor {
    var configurationManager: ConfigurationManager!
    var importationManager: ImportationManager!

    override func loadView() {
        // Creates the view elements.
        let button = NSButton(title: "", target: self, action: #selector(showMenu))
        button.isTransparent = true
        button.menu = NSMenu()
        button.menu!.addItem(
                NSMenuItem(title: NSLocalizedString("pts.continuity.menuItemTitle", comment: ""),
                        action: nil,
                        keyEquivalent: ""))
        view = button
    }

    /// Indicates if this controller can handle data sent by a service. If yes,
    /// readSelection will be called with the data.
    override func validRequestor(
            forSendType sendType: NSPasteboard.PasteboardType?,
            returnType: NSPasteboard.PasteboardType?) -> Any? {
        if let pasteboardType = returnType,
           // Service is image related.
           NSImage.imageTypes.contains(pasteboardType.rawValue) {
            return self  // This object can receive image data.
        } else {
            // Let objects in the responder chain handle the message.
            return super.validRequestor(forSendType: sendType, returnType: returnType)
        }
    }

    /// Processes data from a compatible service, in this case Continuity
    /// Camera.
    func readSelection(from pasteboard: NSPasteboard) -> Bool {
        // Generates a name for a file to save the data to.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        var data: Data?
        let fileName = dateFormatter.string(from: Date())
        var completeName = fileName

        if data == nil {
            data = pasteboard.data(forType: .tiff)
            completeName = "\(fileName).tif"
        }
        if data == nil {
            data = pasteboard.data(forType: .pdf)
            completeName = "\(fileName).pdf"
        }

        if data == nil {
            return false
        }
        // Saves the data in a file and starts the importation process.
        let fileUrl = configurationManager.continuityFolderURL.appendingPathComponent(completeName)
        do {
            if !FileManager.default.fileExists(atPath: configurationManager.continuityFolderURL.path) {
                try FileManager.default.createDirectory(at: configurationManager.continuityFolderURL, withIntermediateDirectories: true)
            }
            try data!.write(to: fileUrl)
            importationManager.queue(document: fileUrl)
        } catch {
            ErrorManager.error(.continuity, key: "pts.error.continuity.save")
        }
        return true
    }

    /// Button callback.
    @objc func showMenu(_ sender: NSButton) {
        guard let menu = view.menu else {
            return
        }
        guard let event = NSApplication.shared.currentEvent else {
            return
        }

        // AppKit uses the Responder Chain to figure out where to insert the
        // Continuity Camera menu items. So making ourselves `firstResponder`
        // here is important.
        // It also means the this object will be the first to receive data from
        // *any* services.
        view.window?.makeFirstResponder(self)
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }
}

/// SwiftUI wrapper for the Continuity Camera NSViewController.
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
