//
//  FileSystem.swift
//  PicToShare/StandardLibrary
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import AppKit
import EonilFSEvents


class FileSystemDocumentSource: DocumentSource {
    private var importCallback: ((AnyObject) -> Void)?
    private let openPanel: NSOpenPanel
    private var monitoredFolder = ""

    private let configuration: Configuration

    required init(with configuration: Configuration) throws {
        self.configuration = configuration
        openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        // Next update : get path from config AND get rid of permissions issues
        try monitoredFolder = FileManager.default
                .url(for: .documentDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true)
                .appendingPathComponent("PTSFolder", isDirectory: true).path


        try EonilFSEvents.startWatching(
                paths: [monitoredFolder],
                for: ObjectIdentifier(self.configuration),
                with: { event in self.processFileFromEvent(event: event) })

    }

    deinit {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(configuration))
    }

    func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
        importCallback = callback
    }

    func promptDocument() {
        openPanel.begin(completionHandler: { /*[self]*/ response in
            if response == NSApplication.ModalResponse.OK {
                //importCallback?(TextDocument())
            }
        })
        openPanel.runModal()
    }

    /// Creates a document and calls the callback method to process the file
    /// The file is loaded from an URL, which is retrieved from an FSEvent
    /// The event is triggered when an action is done in the monitored folder
    ///
    /// - Parameters:
    ///   - event: The EonilFSEventsEvent triggered by the file.
    func processFileFromEvent(event: EonilFSEventsEvent) {
        /// We ignore events triggered by the .DS_STORE hidden file
        if !event.path.contains(".DS_STORE") {
            // Need to check if the file is already existing or not to prevent loops
            if (event.flag) != nil {

                /// Flags "itemRenamed" and "itemIsFile" are required to detect the right files
                /// But rename or move a file outside the folder triggers the same flags
                if ((event.flag?.contains(EonilFSEventsEventFlags.itemRenamed))! &&
                        (event.flag?.contains(EonilFSEventsEventFlags.itemIsFile))!) {

                    print("Event detected : \(event.path)")

                    /// We get rid of everything before the last / and past the last . to get the filename
                    let firstIndex = event.path.lastIndex(of: "/")!
                    let lastIndex = event.path.lastIndex(of: ".")!
                    let fileName = String(event.path[event.path.index(
                            after: firstIndex)..<lastIndex])

                    let fileData = FileManager.default.contents(
                            atPath: event.path)

                    // For now, we just assume that the file is a text file in UTF8
                    if (fileData != nil) {
                        let textDocument = TextDocument(
                                content: String(
                                        decoding: fileData!,
                                        as: UTF8.self),
                                documentName: fileName)

                        // Will trigger the importation when rdy
                        self.importCallback?(textDocument)

                    } else {
                        print("Failed to load file data at URL : \(event.path)")
                    }
                }
            }
        }
    }
}
