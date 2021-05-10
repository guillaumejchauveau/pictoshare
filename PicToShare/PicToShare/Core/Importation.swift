import Foundation

struct ImportationConfiguration {
    var url: URL
    let type: DocumentType
    let context: UserContext?
    let annotators: Set<HashableDocumentAnnotator>
    let integrators: Set<HashableDocumentIntegrator>
}

/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    enum Error: Swift.Error {
        case InputUrlError
        case ScriptExecutionError(status: Int32)
    }

    private let configurationManager: ConfigurationManager
    private var importationQueue: [URL] = []

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
    func importDocument(with importationConfiguration: ImportationConfiguration) {
        guard importationConfiguration.url.isFileURL else {
            return
        }
        var configuration = importationConfiguration
        let inputUrlFolder = configuration.url.deletingLastPathComponent()
        if inputUrlFolder == configurationManager.continuityFolderURL {
            let newDocumentUrl = inputUrlFolder.appendingPathComponent(
                    configuration.type.description + "_" +
                            (configuration.context?.description ?? "") + "_" +
                            configuration.url.lastPathComponent)
            do {
                try FileManager.default.moveItem(at: configuration.url, to: newDocumentUrl)
                configuration.url = newDocumentUrl
            } catch {

            }
        }

        if configuration.type.documentProcessorScript == nil {
            postProcess(documents: [configuration.url], with: configuration)
            return
        }

        if configuration.type.copyBeforeProcessing {
            let copyUrl = inputUrlFolder
                    .appendingPathComponent(configuration.url.deletingPathExtension().lastPathComponent + ".copy")
                    .appendingPathExtension(configuration.url.pathExtension)
            do {
                try FileManager.default.copyItem(at: configuration.url, to: copyUrl)
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
            configuration.type.documentProcessorScript!.path,
            configuration.url.path,
            configuration.url.deletingPathExtension().path
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
            let outputFilesPrefix = configuration.url.deletingPathExtension().lastPathComponent
            var outputUrls = try! FileManager.default.contentsOfDirectory(at: inputUrlFolder,
                            includingPropertiesForKeys: nil)
                    .filter {
                        $0.deletingPathExtension().lastPathComponent == outputFilesPrefix
                    }
            if outputUrls.count > 1 {
                outputUrls.removeAll {
                    $0 == configuration.url
                }
                if configuration.type.removeOriginalOnProcessingByproduct {
                    try? FileManager.default.removeItem(at: configuration.url)
                }
            }
            postProcess(documents: outputUrls, with: configuration)
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

    private func postProcess(documents urls: [URL], with configuration: ImportationConfiguration) {
        let annotationResults = AnnotationResults(configuration.annotators.count,
                urls,
                [
                    configuration.type.description,
                    configuration.context?.description
                ])

        for annotator in configuration.annotators {
            annotator.makeAnnotations(annotationResults.complete)
        }

        for url in urls {
            do {
                let bookmarkData = try url.bookmarkData(options: [.suitableForBookmarkFile])
                try URL.writeBookmarkData(bookmarkData, to: configuration.type.folder.appendingPathComponent(url.lastPathComponent))
            } catch {
                NotificationManager.notifyUser(
                        "Échec de la classification",
                        "PicToShare n'a pas pu créer un marque-page vers le document",
                        "PTS-Bookmark")
            }
        }

        for integrator in configuration.integrators {
            integrator.integrate(documents: urls)
        }
    }
}
