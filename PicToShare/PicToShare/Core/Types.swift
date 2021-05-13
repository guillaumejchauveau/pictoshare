import Foundation
import EventKit

/// Object providing a list of Annotations to add to imported Documents.
/// The Annotations are usually based on information in the current context.
protocol DocumentAnnotator: CustomStringConvertible {
    typealias CompletionHandler = ([String]) -> Void

    /// Document Annotator can run asynchronously (to ask permission to access a
    /// resource for example), so this function takes a completion callback.
    /// The callback must be called with an array of Annotations.
    func makeAnnotations(
            with: ImportationConfiguration,
            _ completion: @escaping CompletionHandler)
}

/// Object attaching the Document file to an external application or content.
protocol DocumentIntegrator: CustomStringConvertible {
    func integrate(documents: [URL], bookmarks: [URL], with: ImportationConfiguration)
}


/// Holds all the information required to import a Document.
struct ImportationConfiguration {
    /// A path to the script used to process the Document.
    var documentProcessorScript: URL? = nil
    /// Indicates if a copy of the file should be made before running the script.
    var copyBeforeProcessing: Bool = true
    /// Indicates if a the original file should be removed if the script creates new files.
    var removeOriginalOnProcessingByproduct: Bool = false
    /// The Document Annotators used to annotate the Document.
    var documentAnnotators: Set<HashableDocumentAnnotator> = []
    /// Additional annotations to add to the Document.
    var additionalDocumentAnnotations: [String] = []
    /// The Document Integrators that will use the Document.
    var documentIntegrators: Set<HashableDocumentIntegrator> = []
    /// The URL of the folder where a bookmark should be placed.
    var bookmarkFolder: URL
    /// Set of calendars for the Calendars Resource.
    var calendars: Set<EKCalendar> = []

    /// Creates a complete configuration using partial configurations.
    init(_ partials: [PartialImportationConfiguration?]) throws {
        var chosenBookmarkFolder: URL? = nil
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
            if let folder = partial.bookmarkFolder {
                chosenBookmarkFolder = folder
            }
            documentAnnotators = documentAnnotators.union(partial.documentAnnotators)
            additionalDocumentAnnotations.append(contentsOf: partial.additionalDocumentAnnotations)
            documentIntegrators = documentIntegrators.union(partial.documentIntegrators)
            calendars = calendars.union(partial.calendars)
        }

        guard let bookmarkFolder = chosenBookmarkFolder else {
            throw PicToShareError.importation
        }
        self.bookmarkFolder = bookmarkFolder
    }
}


/// Object providing some Importation Configuration parameters.
/// Partials can be merged to create a complete Configuration.
protocol PartialImportationConfiguration {
    /// A path to the script used to process the Document.
    var documentProcessorScript: URL? { get }
    /// Indicates if a copy of the file should be made before running the script.
    var copyBeforeProcessing: Bool? { get }
    /// Indicates if a the original file should be removed if the script creates new files.
    var removeOriginalOnProcessingByproduct: Bool? { get }
    /// The Document Annotators used to annotate the Document.
    var documentAnnotators: Set<HashableDocumentAnnotator> { get }
    /// Additional annotations to add to the Document.
    var additionalDocumentAnnotations: [String] { get }
    /// The Document Integrators that will use the Document.
    var documentIntegrators: Set<HashableDocumentIntegrator> { get }
    /// The URL of the folder where a bookmark should be placed.
    var bookmarkFolder: URL? { get }
    /// Set of calendars for the Calendars Resource.
    var calendars: Set<EKCalendar> { get }
}


/// Default implementation for Partial Configuration.
extension PartialImportationConfiguration {
    var documentProcessorScript: URL? {
        nil
    }
    var copyBeforeProcessing: Bool? {
        nil
    }
    var removeOriginalOnProcessingByproduct: Bool? {
        nil
    }
    var documentAnnotators: Set<HashableDocumentAnnotator> {
        []
    }
    var additionalDocumentAnnotations: [String] {
        []
    }
    var documentIntegrators: Set<HashableDocumentIntegrator> {
        []
    }
    var bookmarkFolder: URL? {
        nil
    }
    var calendars: Set<EKCalendar> {
        []
    }
}


// As Protocols cannot conform to Hashable, the following wrappers are used.

struct HashableDocumentAnnotator: DocumentAnnotator, Hashable {
    static func ==(lhs: HashableDocumentAnnotator, rhs: HashableDocumentAnnotator) -> Bool {
        lhs.description == rhs.description
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    func makeAnnotations(
            with configuration: ImportationConfiguration,
            _ completion: @escaping CompletionHandler) {
        annotator.makeAnnotations(with: configuration, completion)
    }

    var description: String {
        annotator.description
    }

    private let annotator: DocumentAnnotator

    init(_ annotator: DocumentAnnotator) {
        self.annotator = annotator
    }
}

struct HashableDocumentIntegrator: DocumentIntegrator, Hashable {
    static func ==(lhs: HashableDocumentIntegrator, rhs: HashableDocumentIntegrator) -> Bool {
        lhs.description == rhs.description
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }


    func integrate(documents: [URL], bookmarks: [URL], with configuration: ImportationConfiguration) {
        integrator.integrate(documents: documents, bookmarks: bookmarks, with: configuration)
    }

    var description: String {
        integrator.description
    }

    private let integrator: DocumentIntegrator

    init(_ integrator: DocumentIntegrator) {
        self.integrator = integrator
    }
}
