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

        if type.documentProcessorScript == nil {
            postProcessDocuments(urls: [inputUrl], with: type)
            return
        }

        let inputUrlFolder = inputUrl.deletingLastPathComponent()
        if type.copyBeforeProcessing {
            let copyUrl = inputUrlFolder
                    .appendingPathComponent(inputUrl.deletingPathExtension().lastPathComponent + ".copy")
                    .appendingPathExtension(inputUrl.pathExtension)
            do {
                try FileManager.default.copyItem(at: inputUrl, to: copyUrl)
            } catch {
                NotificationManager.notifyUser(
                        "Échec de l'importation",
                        "PicToShare n'a pas pu copier le document original",
                        "PTS-CalendarIntegration")
            }
        }

        // Executes the script.
        let scriptProcess = Process()
        scriptProcess.currentDirectoryURL = inputUrlFolder
        scriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        scriptProcess.arguments = [
            type.documentProcessorScript!.path,
            inputUrl.path,
            inputUrl.deletingPathExtension().path
        ]

        // Script callback.
        scriptProcess.terminationHandler = { [self] _ in
            guard scriptProcess.terminationStatus == 0 else {
                NotificationManager.notifyUser(
                        "Échec de l'importation",
                        "Le script configuré s'est terminé avec une erreur: \(scriptProcess.terminationStatus)",
                        "PTS-ProcessorScriptRun")
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
            postProcessDocuments(urls: outputUrls, with: type)
        }

        // Runs the script asynchronously.
        do {
            try scriptProcess.run()
        } catch {
            NotificationManager.notifyUser(
                    "Échec de l'importation",
                    "PicToShare n'a pas pu exécuter le script configuré",
                    "PTS-ProcessorScriptRun")
        }
    }


    private class AnnotationResults {
        private var keywords: [String] = []
        private var remainingCount: Int
        private let urls: [URL]

        init(_ annotatorCount: Int, _ urls: [URL], _ defaults: [String?]) {
            remainingCount = annotatorCount
            self.urls = urls
            keywords.append(contentsOf: defaults.compactMap({ $0 }))

            if annotatorCount == 0 {
                write()
            }
        }

        func complete(_ keywords: [String]) {
            remainingCount -= 1
            self.keywords.append(contentsOf: keywords)

            if remainingCount <= 0 {
                write()
            }
        }

        private func write() {
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary

                let itemKeywords = try encoder.encode(keywords)

                for url in urls {
                    try url.setExtendedAttribute(
                            data: itemKeywords,
                            forName: "com.apple.metadata:kMDItemKeywords")
                }
            } catch {
                NotificationManager.notifyUser(
                        "Échec de l'annotation",
                        "PicToShare n'a pas pu écrire les annotations",
                        "PTS-Annotation")
            }
        }
    }

    private func postProcessDocuments(urls: [URL], with type: DocumentType) {
        let contextAnnotators = type.documentAnnotators
                .union(configurationManager.currentUserContext?.documentAnnotators ?? [])
        let documentIntegrators = type.documentIntegrators
                .union(configurationManager.currentUserContext?.documentIntegrators ?? [])

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
            do {
                let bookmarkData = try url.bookmarkData(options: [.suitableForBookmarkFile])
                try URL.writeBookmarkData(bookmarkData, to: type.folder.appendingPathComponent(url.lastPathComponent))
            } catch {
                NotificationManager.notifyUser(
                        "Échec de la classification",
                        "PicToShare n'a pas pu créer un marque-page vers le document",
                        "PTS-Bookmark")
            }
        }

        for integrator in documentIntegrators {
            integrator.integrate(documents: urls)
        }
    }
}
