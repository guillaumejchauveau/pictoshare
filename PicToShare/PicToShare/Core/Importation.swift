import Foundation

extension PicToShareError {
    static let importation = PicToShareError(type: "pts.error.importation")
}

struct ImportationConfiguration {
    var documentProcessorScript: URL? = nil
    var copyBeforeProcessing: Bool = true
    var removeOriginalOnProcessingByproduct: Bool = false
    var documentAnnotators: Set<HashableDocumentAnnotator> = []
    var additionalDocumentAnnotations: [String] = []
    var documentIntegrators: Set<HashableDocumentIntegrator> = []
    var folder: URL

    init(_ partials: [PartialImportationConfiguration?]) throws {
        var chosenFolder: URL? = nil
        for partial in partials.compactMap({ $0 }) {
            if let script = partial.documentProcessorScript {
                documentProcessorScript = script
            }
            if let copy = partial.copyBeforeProcessing {
                copyBeforeProcessing = copy
            }
            if let remove = partial.removeOriginalOnProcessingByproduct {
                removeOriginalOnProcessingByproduct = remove
            }
            if let folder = partial.folder {
                chosenFolder = folder
            }
            documentAnnotators = documentAnnotators.union(partial.documentAnnotators)
            additionalDocumentAnnotations.append(contentsOf: partial.additionalDocumentAnnotations)
            documentIntegrators = documentIntegrators.union(partial.documentIntegrators)
        }

        guard let folder = chosenFolder else {
            throw PicToShareError.importation
        }
        self.folder = folder
    }
}

/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    private let configurationManager: ConfigurationManager
    private var importationQueue: [URL] = []

    init(_ configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    var queueHead: URL? {
        importationQueue.first
    }

    func queue(document url: URL) {
        importationQueue.append(url)
        objectWillChange.send()
    }

    func queue<S>(documents urls: S) where S.Element == URL, S: Sequence {
        importationQueue.append(contentsOf: urls)
        objectWillChange.send()
    }

    func popQueueHead() -> URL? {
        let document = importationQueue.removeFirst()
        objectWillChange.send()
        return document
    }

    func importDocument(_ document: URL, with configurations: PartialImportationConfiguration?...) {
        do {
            let configuration = try ImportationConfiguration(configurations)
            importDocument(document, with: configuration)
        } catch {
            ErrorManager.error(.importation, key: "pts.error.importation.configuration")
        }
    }

    func importDocument(_ document: URL, with configuration: ImportationConfiguration) {
        guard document.isFileURL else {
            return
        }
        let documentFolder = document.deletingLastPathComponent()

        if configuration.documentProcessorScript == nil {
            postProcess(documents: [document], with: configuration)
            return
        }

        if configuration.copyBeforeProcessing {
            let copyUrl = documentFolder
                    .appendingPathComponent(
                            document.deletingPathExtension().lastPathComponent + "." +
                                    NSLocalizedString("pts.copySuffix", comment: ""))
                    .appendingPathExtension(document.pathExtension)
            do {
                try FileManager.default.copyItem(at: document, to: copyUrl)
            } catch {
                ErrorManager.error(.importation, key: "pts.error.importation.copyBeforeProcessing")
            }
        }

        // Executes the script.
        let scriptProcess = Process()
        scriptProcess.currentDirectoryURL = documentFolder
        scriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        scriptProcess.arguments = [
            configuration.documentProcessorScript!.path,
            document.path,
            document.deletingPathExtension().path
        ]

        // Script callback.
        scriptProcess.terminationHandler = { [self] _ in
            guard scriptProcess.terminationStatus == 0 else {
                ErrorManager.error(.importation, String(format:
                NSLocalizedString("pts.error.importation.scriptTermination", comment: ""),
                        scriptProcess.terminationStatus))
                return
            }

            // Finds the output(s) of the script.
            let outputFilesPrefix = document.deletingPathExtension().lastPathComponent
            var outputUrls = try! FileManager.default.contentsOfDirectory(at: documentFolder,
                            includingPropertiesForKeys: nil)
                    .filter {
                        $0.deletingPathExtension().lastPathComponent == outputFilesPrefix
                    }
            if outputUrls.count > 1 {
                outputUrls.removeAll {
                    $0 == document
                }
                if configuration.removeOriginalOnProcessingByproduct {
                    try? FileManager.default.removeItem(at: document)
                }
            }
            postProcess(documents: outputUrls, with: configuration)
        }

        // Runs the script asynchronously.
        do {
            try scriptProcess.run()
        } catch {
            ErrorManager.error(.importation, key: "pts.error.importation.scriptRun")
        }
    }


    private class AnnotationResults {
        private var keywords: [String]
        private var remainingCount: Int
        private let urls: [URL]

        init(_ annotatorCount: Int, _ urls: [URL], _ defaults: [String] = []) {
            keywords = defaults
            remainingCount = annotatorCount
            self.urls = urls

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
                ErrorManager.error(.importation, key: "pts.error.importation.annotation")
            }
        }
    }

    private func postProcess(documents urls: [URL], with configuration: ImportationConfiguration) {
        let annotationResults = AnnotationResults(
                configuration.documentAnnotators.count,
                urls,
                configuration.additionalDocumentAnnotations)

        for annotator in configuration.documentAnnotators {
            annotator.makeAnnotations(annotationResults.complete)
        }

        for url in urls {
            do {
                let bookmarkData = try url.bookmarkData(options: [.suitableForBookmarkFile])
                try URL.writeBookmarkData(bookmarkData,
                        to: configuration.folder.appendingPathComponent(url.lastPathComponent))
            } catch {
                ErrorManager.error(.importation, key: "pts.error.importation.bookmark")
            }
        }

        for integrator in configuration.documentIntegrators {
            integrator.integrate(documents: urls)
        }
    }
}
