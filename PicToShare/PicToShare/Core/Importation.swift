//
//  Importation.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 24/02/2021.
//

import Foundation


/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    enum Error: Swift.Error {
        case InputUrlError
        case ScriptExecutionError(status: Int32)
    }

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
        if let osaScriptUrl = type.documentProcessorScript {
            // Copies the input file for safety if it is not in the PTS folder.
            let inputUrlFolder = inputUrl.deletingLastPathComponent()
            if inputUrlFolder != configurationManager.documentFolderURL
                       && type.copyBeforeProcessing {
                let copyUrl = inputUrlFolder
                        .appendingPathComponent(inputUrl.deletingPathExtension().lastPathComponent + ".copy")
                        .appendingPathExtension(inputUrl.pathExtension)
                try! FileManager.default.copyItem(at: inputUrl, to: copyUrl)
            }

            // Executes the script.
            let scriptProcess = Process()
            scriptProcess.currentDirectoryURL = inputUrlFolder
            scriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            scriptProcess.arguments = [
                osaScriptUrl.path,
                inputUrl.path,
                inputUrl.deletingPathExtension().path
            ]
            // Script callback.
            scriptProcess.terminationHandler = { _ in
                guard scriptProcess.terminationStatus == 0 else {
                    // TODO
                    return
                }

                // Finds the output(s) of the script.
                let outputFilesPrefix = inputUrl.deletingPathExtension().lastPathComponent
                var outputUrls = try! FileManager.default.contentsOfDirectory(at: inputUrlFolder,
                                                                              includingPropertiesForKeys: nil)
                        .filter {
                            $0.deletingPathExtension().lastPathComponent == outputFilesPrefix
                        }
                if outputUrls.count > 1 && type.removeOriginalOnProcessingByproduct {
                    outputUrls.removeAll {
                        $0 == inputUrl
                    }
                    try? FileManager.default.removeItem(at: inputUrl)
                }
                self.postProcessDocuments(urls: outputUrls, with: type)
            }
            // Runs the script asynchronously.
            try! scriptProcess.run()
        } else {
            postProcessDocuments(urls: [inputUrl], with: type)
        }
    }

    
    private class AnnotationResults {
        private var keywords: [String] = []
        private var remainingCount: Int
        private let urls: [URL]
        
        init(_ annotatorCount: Int, _ urls: [URL], _ defaults: [String?]) {
            remainingCount = annotatorCount
            self.urls = urls
            keywords.append(contentsOf: defaults.compactMap({$0}))
            if annotatorCount == 0 {
                write()
            }
        }
        
        
        func complete(_ result: Result<[String], DocumentAnnotatorError>) {
            remainingCount -= 1
            switch result {
                case .success(let keywords):
                    self.keywords.append(contentsOf: keywords)
                default:
                    break
            }
            
            if remainingCount <= 0 {
                write()
            }
        }

        private func write() {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary

            let itemKeywords = try! encoder.encode(keywords)

            for url in urls {
                try! url.setExtendedAttribute(
                    data: itemKeywords,
                    forName: "com.apple.metadata:kMDItemKeywords")
            }
        }
    }
    
    private func postProcessDocuments(urls: [URL], with type: DocumentType) {
        var contextAnnotators = type.documentAnnotators
        contextAnnotators.append(contentsOf: configurationManager.currentUserContext?.documentAnnotators ?? [])
        var documentIntegrators = type.documentIntegrators
        documentIntegrators.append(contentsOf: configurationManager.currentUserContext?.documentIntegrators ?? [])

        let annotationResults = AnnotationResults(contextAnnotators.count,
                                                  urls,
                                                  [
                                                    type.description,
                                                    configurationManager.currentUserContext?.description
                                                  ])
        
        for annotator in contextAnnotators {
            annotator.makeAnnotations(annotationResults.complete)
        }
        
        for url in urls {
            let bookmarkData = try! url.bookmarkData(options: [.suitableForBookmarkFile])
            try! URL.writeBookmarkData(bookmarkData,
                                       to: type.folder.appendingPathComponent(url.lastPathComponent))
        }

        for integrator in documentIntegrators {
            integrator.integrate(documents: urls)
        }
    }
}
