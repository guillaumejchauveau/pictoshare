import Foundation

/// Object providing a list of Annotations to add to imported Documents.
/// The Annotations are usually based on information in the current context.
protocol DocumentAnnotator: CustomStringConvertible {
    typealias CompletionHandler = ([String]) -> Void

    /// Document Annotator can run asynchronously (to ask permission to access a
    /// resource for example), so this function takes a completion callback.
    /// The callback must be called with an array of Annotations.
    func makeAnnotations(_ completion: @escaping CompletionHandler)
}

/// Object attaching the Document file to an external application or content.
protocol DocumentIntegrator: CustomStringConvertible {
    func integrate(documents: [URL])
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
}


// As Protocols cannot conform to Hashable, the following wrappers are used.

struct HashableDocumentAnnotator: DocumentAnnotator, Hashable {
    static func ==(lhs: HashableDocumentAnnotator, rhs: HashableDocumentAnnotator) -> Bool {
        lhs.description == rhs.description
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    func makeAnnotations(_ completion: @escaping CompletionHandler) {
        annotator.makeAnnotations(completion)
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


    func integrate(documents: [URL]) {
        integrator.integrate(documents: documents)
    }

    var description: String {
        integrator.description
    }

    private let integrator: DocumentIntegrator

    init(_ integrator: DocumentIntegrator) {
        self.integrator = integrator
    }
}
