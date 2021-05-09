import Foundation

struct ImportationMetadata {
    let url: URL
    let type: DocumentType
    let annotators: Set<HashableDocumentAnnotator>
    let integrators: Set<HashableDocumentIntegrator>
}

/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    enum Error: Swift.Error {
        case InputUrlError
        case ScriptExecutionError(status: Int32)
    }

    private var importationQueue: [URL] = []
    private let configurationManager: ConfigurationManager

    init(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    var queueHead: URL? {
        importationQueue.first
    }

    var queueCount: Int {
        importationQueue.count
    }

    func queue(document url: URL) {
        importationQueue.append(url)
        objectWillChange.send()
    }

    func queue<S>(documents urls: S) where S.Element == URL, S: Sequence {
        importationQueue.append(contentsOf: urls)
        objectWillChange.send()
    }

    func popQueueHead() {
        importationQueue.removeFirst()
        objectWillChange.send()
    }

    /// Imports a Document given a Document Type.
    ///
    /// - Parameters:
    func importDocument(with metadata: ImportationMetadata) {
        guard metadata.url.isFileURL else {
            return
        }

        if metadata.type.documentProcessorScript == nil {
            postProcess(documents: [metadata.url], with: metadata)
            return
        }

        let inputUrlFolder = metadata.url.deletingLastPathComponent()
        if metadata.type.copyBeforeProcessing {
            let copyUrl = inputUrlFolder
                    .appendingPathComponent(metadata.url.deletingPathExtension().lastPathComponent + ".copy")
                    .appendingPathExtension(metadata.url.pathExtension)
            do {
                try FileManager.default.copyItem(at: metadata.url, to: copyUrl)
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
            metadata.type.documentProcessorScript!.path,
            metadata.url.path,
            metadata.url.deletingPathExtension().path
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
            let outputFilesPrefix = metadata.url.deletingPathExtension().lastPathComponent
            var outputUrls = try! FileManager.default.contentsOfDirectory(at: inputUrlFolder,
                            includingPropertiesForKeys: nil)
                    .filter {
                        $0.deletingPathExtension().lastPathComponent == outputFilesPrefix
                    }
            if outputUrls.count > 1 && metadata.type.removeOriginalOnProcessingByproduct {
                outputUrls.removeAll {
                    $0 == metadata.url
                }
                try? FileManager.default.removeItem(at: metadata.url)
            }
            postProcess(documents: outputUrls, with: metadata)
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

    private func postProcess(documents urls: [URL], with metadata: ImportationMetadata) {
        let annotationResults = AnnotationResults(metadata.annotators.count,
                urls,
                [
                    metadata.type.description,
                    configurationManager.currentUserContext?.description
                ])

        for annotator in metadata.annotators {
            annotator.makeAnnotations(annotationResults.complete)
        }

        for url in urls {
            do {
                let bookmarkData = try url.bookmarkData(options: [.suitableForBookmarkFile])
                try URL.writeBookmarkData(bookmarkData, to: metadata.type.folder.appendingPathComponent(url.lastPathComponent))
            } catch {
                NotificationManager.notifyUser(
                        "Échec de la classification",
                        "PicToShare n'a pas pu créer un marque-page vers le document",
                        "PTS-Bookmark")
            }
        }

        for integrator in metadata.integrators {
            integrator.integrate(documents: urls)
        }
    }
}
