import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print(urls)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSRegisterServicesProvider(self, "PicToShare-Services")
        print("hello")
    }

    @objc func insertContent(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        print("content")
    }

    @objc func insertLink(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        print("link")
        while true {}
        /*
                let bookmarkData = try url.bookmarkData(options: [.suitableForBookmarkFile])

                switch metadata.pasteboardInsertMode {
                case .link(_):
                    let item = NSPasteboardItem()
                    item.setData(bookmarkData, forType: .init(UTType.urlBookmarkData.identifier))
                    item.setData(url.dataRepresentation, forType: .fileURL)
                    item.setString(url.path, forType: .string)
                    pasteboardItems.append(item)*/
    }
}

