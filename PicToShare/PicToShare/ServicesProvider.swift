import Cocoa

/// Application services provider.
class ServicesProvider {
    private let importationManager: ImportationManager

    init(_ importationManager: ImportationManager) {
        self.importationManager = importationManager
        NSRegisterServicesProvider(self, "PicToShare")
    }

    /// Services for importing files from outside PTS, like from the Finder.
    @objc func importFiles(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let items = pboard.pasteboardItems else {
            return
        }
        importationManager.queue(documents: items.compactMap { item in
            guard let data = item.data(forType: .fileURL) else {
                return nil
            }
            return URL(dataRepresentation: data, relativeTo: nil)
        })
        PTSApp.openPTS()
    }
}
