import Foundation

/// Object providing a list of keywords to add to imported Documents.
/// The keywords are usually based on information in the current context.
protocol DocumentAnnotator: CustomStringConvertible {
    typealias CompletionHandler = ([String]) -> Void

    func makeAnnotations(_ completion: @escaping CompletionHandler)
}

enum DocumentAnnotatorError: Error {
    case permissionError
}

/// Object attaching the Document file to an external application or content.
protocol DocumentIntegrator: CustomStringConvertible {
    func integrate(documents: [URL])
}


protocol DocumentType: CustomStringConvertible {
    /// A path to the script used to process the Document.
    var documentProcessorScript: URL? { get }
    /// Indicates if a copy of the file should be made before running the script.
    var copyBeforeProcessing: Bool { get }
    /// Indicates if a the original file should be removed if the script creates new files.
    var removeOriginalOnProcessingByproduct: Bool { get }
    /// The Document Annotators used to annotate the Document.
    var documentAnnotators: Set<HashableDocumentAnnotator> { get }
    /// The Document Integrators that will use the Document.
    var documentIntegrators: Set<HashableDocumentIntegrator> { get }
    /// The URL of the folder containing links to all Documents of this Type.
    var folder: URL { get }
}

protocol UserContext: CustomStringConvertible {
    /// Additional Document Annotators.
    var documentAnnotators: Set<HashableDocumentAnnotator> { get }
    /// Additional Document Integrators.
    var documentIntegrators: Set<HashableDocumentIntegrator> { get }
}


// As Protocols cannot conform to Hashable, the following implement a compromise.

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
