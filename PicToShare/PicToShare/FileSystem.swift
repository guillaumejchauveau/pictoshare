//
//  FileSystem.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import AppKit
import EonilFSEvents


class FileSystemDocumentSource {
    private let importationManager: ImportationManager
    private let openPanel = NSOpenPanel()

    init(_ configurationManager: ConfigurationManager, _ importationManager: ImportationManager) throws {
        self.importationManager = importationManager
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true

        if configurationManager.documentFolderURL != nil {
            try EonilFSEvents.startWatching(
                    paths: [configurationManager.documentFolderURL!.path],
                    for: ObjectIdentifier(self),
                    with: processEvent)
        }
    }

    deinit {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(self))
    }

    func promptDocument() {
        openPanel.begin { [self] response in
            guard response == NSApplication.ModalResponse.OK
                          && openPanel.urls.count > 0 else {
                return
            }
            importationManager.queue(documents: openPanel.urls)
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
        guard FileManager.default.fileExists(atPath: event.path) else {
            return
        }
        importationManager.queue(document: URL(fileURLWithPath: event.path))
    }
}
