//
//  FileSystem.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import AppKit
import EonilFSEvents


class FileSystemDocumentSource {
    private var importCallback: ((URL) -> Void)?
    private let openPanel = NSOpenPanel()

    init(path: String) throws {
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true

        let monitoredFolder = try FileManager.default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent(path, isDirectory: true).path

        try EonilFSEvents.startWatching(
            paths: [monitoredFolder],
            for: ObjectIdentifier(self),
            with: processEvent)
    }
    
    deinit {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(self))
    }

    func setImportCallback(_ callback: @escaping (URL) -> Void) {
        importCallback = callback
    }

    func promptDocument() {
        openPanel.begin { [self] response in
            guard response == NSApplication.ModalResponse.OK
                    && openPanel.urls.count > 0 else {
                return
            }
            importCallback?(openPanel.urls[0])
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

        importCallback?(URL(fileURLWithPath: event.path))
    }
}
