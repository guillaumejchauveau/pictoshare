import Foundation
import EventKit

extension PicToShareError {
    static let importation = PicToShareError(type: "pts.error.importation")
}


/// Object responsible of the Importation process.
class ImportationManager: ObservableObject {
    @Published private var importationQueue: [URL] = []

    /// Top importation queue Document.
    var queueHead: URL? {
        importationQueue.first
    }

    /// Adds a Document to the queue.
    func queue(document url: URL) {
        importationQueue.append(url)
    }

    /// Adds multiple Documents to the queue.
    func queue<S>(documents urls: S) where S.Element == URL, S: Sequence {
        importationQueue.append(contentsOf: urls)
    }

    /// Removes the top Document of the queue and returns it.
    func popQueueHead() -> URL? {
        importationQueue.removeFirst()
    }

    /// Imports the given Document with a list of partial importation
    /// configuration used to create the complete one.
    func importDocument(_ document: URL, with configurations: PartialImportationConfiguration?...) {
        do {
            let configuration = try ImportationConfiguration(configurations)
            importDocument(document, with: configuration)
        } catch {
            ErrorManager.error(.importation, key: "pts.error.importation.configuration")
        }
    }

    /// Converts a URL in order to use it as a processing script argument.
    private func convert(url: URL) -> String {
        "\"\(url.absoluteString.removingPercentEncoding!)\""
    }

    /// Imports the given Document with a complete importation configuration.
    func importDocument(_ document: URL, with configuration: ImportationConfiguration) {
        guard document.isFileURL else {
            return
        }
        let documentFolder = document.deletingLastPathComponent()

        if configuration.documentProcessorScript == nil {
            // Continues to process the Document, no scripts to execute.
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

        // Executes the processor script.
        let scriptProcess = Process()
        scriptProcess.currentDirectoryURL = documentFolder
        scriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        scriptProcess.arguments = [
            configuration.documentProcessorScript!.absoluteString,
            convert(url: document),
            convert(url: document.deletingPathExtension())
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
            // Continues the importation process using the output(s) of the
            // processor script.
            postProcess(documents: outputUrls, with: configuration)
        } // End of the script callback.

        // Runs the script asynchronously.
        do {
            try scriptProcess.run()
        } catch {
            ErrorManager.error(.importation, key: "pts.error.importation.scriptRun")
        }
    }

    /// Document Annotators can run asynchronously, we need to gather all the
    /// annotations made before writing them to the Document. An instance of
    /// this object is shared by the completion handlers of the Annotators.
    private class AnnotationResults {
        /// The annotations made.
        private var annotations: [String]
        /// The number of Annotator that did not complete yet.
        private var remainingCount: Int
        /// The target Document(s).
        private let urls: [URL]

        init(_ annotatorCount: Int, _ urls: [URL], _ defaults: [String] = []) {
            annotations = defaults
            remainingCount = annotatorCount
            self.urls = urls

            if annotatorCount == 0 {
                write()
            }
        }

        /// The completion callback for the Annotators.
        func complete(_ annotations: [String]) {
            remainingCount -= 1
            self.annotations.append(contentsOf: annotations)

            if remainingCount <= 0 {
                write()
            }
        }

        /// Writes the Annotations to the Documents.
        private func write() {
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary

                let itemKeywords = try encoder.encode(annotations)

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

    /// Continues the Importation process after the processor script completed
    /// (or directly if no scripts specified).
    private func postProcess(documents urls: [URL], with configuration: ImportationConfiguration) {
        let annotationResults = AnnotationResults(
                configuration.documentAnnotators.count,
                urls,
                configuration.additionalDocumentAnnotations)

        for annotator in configuration.documentAnnotators {
            annotator.makeAnnotations(with: configuration, annotationResults.complete)
        }

        var bookmarks: [URL] = []
        for url in urls {
            do {
                let bookmarkData = try url.bookmarkData(options: [.suitableForBookmarkFile])
                let bookmarkUrl = configuration.bookmarkFolder.appendingPathComponent(url.lastPathComponent)
                try URL.writeBookmarkData(bookmarkData, to: bookmarkUrl)
                bookmarks.append(bookmarkUrl)
            } catch {
                ErrorManager.error(.importation, key: "pts.error.importation.bookmark")
            }
        }

        for integrator in configuration.documentIntegrators {
            integrator.integrate(documents: urls, bookmarks: bookmarks, with: configuration)
        }
    }
}
