//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import SwiftUI
import Quartz

enum ImportationError: Error {
    case InputUrlError
    case ScriptExecutionError(status: Int32)
}

/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    private var documentQueue: [URL] = []
    private let configurationManager: ConfigurationManager

    init(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    var queueHead: URL? {
        documentQueue.first
    }

    var queueCount: Int {
        documentQueue.count
    }

    func queue(document url: URL) {
        documentQueue.append(url)
        objectWillChange.send()
    }

    func queue<S>(documents urls: S) where S.Element == URL, S: Sequence {
        documentQueue.append(contentsOf: urls)
        objectWillChange.send()
    }

    func popQueueHead() {
        documentQueue.removeFirst()
        objectWillChange.send()
    }

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    ///   - inputUrl: The Document to import.
    ///   - type: The Type to use for importation.
    func importDocument(_ inputUrl: URL, with type: DocumentType) {
        guard inputUrl.isFileURL else {
            return
        }
        if let osaScriptUrl = type.contentAnnotatorScript {
            // Copies the input file for safety if it is not in the Documents folder.
            var targetUrl = inputUrl
            let targetFolderUrl = inputUrl.deletingLastPathComponent()
            if targetFolderUrl != configurationManager.documentFolderURL
                       && type.copyBeforeScript {
                targetUrl = targetFolderUrl
                        .appendingPathComponent(inputUrl.deletingPathExtension().lastPathComponent + "_copy")
                        .appendingPathExtension(inputUrl.pathExtension)
                try! FileManager.default.copyItem(at: inputUrl, to: targetUrl)
            }

            // Executes the script.
            let scriptProcess = Process()
            scriptProcess.currentDirectoryURL = targetFolderUrl
            scriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            scriptProcess.arguments = [osaScriptUrl.path, targetUrl.path, targetUrl.deletingPathExtension().path]
            // Script callback.
            scriptProcess.terminationHandler = { _ in
                guard scriptProcess.terminationStatus == 0 else {
                    return
                }

                // Finds the output(s) of the script.
                let outputFilesPrefix = targetUrl.deletingPathExtension().lastPathComponent
                var outputUrls = try! FileManager.default.contentsOfDirectory(at: targetFolderUrl, includingPropertiesForKeys: nil)
                        .filter {
                            $0.deletingPathExtension().lastPathComponent == outputFilesPrefix
                        }
                if outputUrls.count > 1 {
                    outputUrls.removeAll {
                        $0 == targetUrl
                    }
                    try! FileManager.default.removeItem(at: targetUrl)
                }
                self.postProcessDocuments(urls: outputUrls, with: type)
            }
            // Runs the script asynchronously.
            try! scriptProcess.run()
        } else {
            postProcessDocuments(urls: [inputUrl], with: type)
        }
    }

    private func postProcessDocuments(urls: [URL], with type: DocumentType) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        var annotations = type.contextAnnotators.flatMap {
            $0.keywords
        }
        annotations.append(type.description)
        let itemKeywords = try! encoder.encode(annotations)

        for url in urls {
            try! url.setExtendedAttribute(
                    data: itemKeywords,
                    forName: "com.apple.metadata:kMDItemKeywords")

            let bookmarkData = try! url.bookmarkData(options: [.suitableForBookmarkFile])
            try! URL.writeBookmarkData(bookmarkData, to: type.folder.appendingPathComponent(url.lastPathComponent))
        }
    }
}

struct ImportationView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var importationManager: ImportationManager
    @State private var selectedType = 0
    @State private var processedCount = 0

    struct Preview: NSViewRepresentable {
        @ObservedObject var importationManager: ImportationManager

        func makeNSView(context: Context) -> QLPreviewView {
            let view = QLPreviewView(
                    frame: NSRect(x: 0, y: 0, width: 230, height: 250),
                    style: .compact)!

            view.previewItem = importationManager.queueHead as QLPreviewItem?
            return view
        }

        func updateNSView(_ nsView: QLPreviewView, context: Context) {
            nsView.previewItem = importationManager.queueHead as QLPreviewItem?
        }
    }

    var body: some View {
        VStack {
            Preview(importationManager: importationManager)
            HStack {
                Text("\(processedCount + 1) sur \(processedCount + importationManager.queueCount)")
            }
        }.frame(width: 230, height: 300).padding(.trailing, 20)
        VStack {
            GroupBox {
                ScrollView {
                    Spacer()
                    Picker("", selection: $selectedType) {
                        ForEach(configurationManager.types.indices,
                                id: \.self) { index in
                            Text(configurationManager.types[index].description)
                                    .frame(width: 200)
                        }
                    }.pickerStyle(RadioGroupPickerStyle())
                }
            }
            HStack {
                Button("Ignorer") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    importationManager.popQueueHead()
                    processedCount += 1
                }
                Button("Importer") {
                    guard importationManager.queueHead != nil else {
                        return
                    }
                    guard selectedType < configurationManager.types.count &&
                                  selectedType >= 0 else {
                        return
                    }
                    importationManager.importDocument(
                            importationManager.queueHead!,
                            with: configurationManager.types[selectedType])
                    importationManager.popQueueHead()
                    processedCount += 1
                }.buttonStyle(AccentButtonStyle())
            }
        }.frame(width: 230, height: 300)
    }
}
