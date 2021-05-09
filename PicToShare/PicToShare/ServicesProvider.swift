import Cocoa

class ServicesProvider {
    private let importationManager: ImportationManager
    init(_ importationManager: ImportationManager) {
        self.importationManager = importationManager
        NSRegisterServicesProvider(self, "PicToShare")
    }

    @objc func insertContent(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        importationManager.nextImportPasteboardInsertMode = .content(pboard: pboard)
        PTSApp.openPTSUrl()
    }

    @objc func insertLink(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        importationManager.nextImportPasteboardInsertMode = .link(pboard: pboard)
        PTSApp.openPTSUrl()
    }
}
