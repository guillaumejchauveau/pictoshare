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
    private let openPanel = NSOpenPanel()
    private var monitoredFolder: String

    private let configuration: Configuration

    required init(with configuration: Configuration) throws {
        self.configuration = configuration

        guard configuration["path"] != nil else {
            throw Configuration.Error.unsetKey("path")
        }
        guard let path = configuration["path"] as? String else {
            throw Configuration.Error.invalidValue("path")
        }

        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        // Next update : get rid of permissions issues
        try monitoredFolder = FileManager.default
                .url(for: .documentDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true)
                .appendingPathComponent(path, isDirectory: true).path

        try EonilFSEvents.startWatching(
                paths: [monitoredFolder],
                for: ObjectIdentifier(self.configuration),
                with: processEvent)
    }

    deinit {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(configuration))
    }

    func setImportCallback(_ callback: @escaping (AnyObject) -> Void) {
        importCallback = callback
    }

    func promptDocument() {
        openPanel.begin { [self] response in
            guard response == NSApplication.ModalResponse.OK
                          && openPanel.urls.count > 0 else {
                return
            }
            processTxt(openPanel.urls[0].path)
        }
    }

    /// Creates a document and calls the callback method to process the file
    /// The file is loaded from an URL, which is retrieved from an FSEvent
    /// The event is triggered when an action is done in the monitored folder
    ///
    /// - Parameters:
    ///   - event: The EonilFSEventsEvent triggered by the file.
    private func processEvent(_ event: EonilFSEventsEvent) {
        guard let flags = event.flag else {
            return
        }
        // We ignore events triggered by the .DS_STORE hidden file
        guard !event.path.contains(".DS_STORE")
                      && flags.contains(.itemIsFile)
                      && (flags.contains(.itemRenamed)
                || flags.contains(.itemCreated)) else {
            return
        }

        processTxt(event.path)
    }

    private func processTxt(_ path: String) {
        guard let fileData = FileManager.default
                .contents(atPath: path) else {
            return
        }

        // We get rid of everything before the last / and past the last .
        //to get the filename
        let firstIndex = path.lastIndex(of: "/")!
        let lastIndex = path.lastIndex(of: ".")!
        let fileName = String(path[path.index(after: firstIndex)..<lastIndex])

        let textDocument = TextDocument(
                content: String(decoding: fileData, as: UTF8.self),
                documentName: fileName)

        importCallback?(textDocument)
    }
}
