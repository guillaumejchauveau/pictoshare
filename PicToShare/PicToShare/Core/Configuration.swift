import Foundation
import Combine
import EventKit


/// Implementation of a Partial Importation Configuration, presented to the user as `Document Type`.
class DocumentTypeMetadata: PartialImportationConfiguration, ObservableObject,
        CustomStringConvertible {
    private let configurationManager: ConfigurationManager
    private var subscriber: AnyCancellable!
    private var calendarResourceSubscriber: AnyCancellable!

    var savedDescription: String
    @Published var description: String
    @Published var documentProcessorScript: URL?
    @Published var copyBeforeProcessing: Bool?
    @Published var removeOriginalOnProcessingByproduct: Bool?
    @Published var documentAnnotators: Set<HashableDocumentAnnotator>
    var additionalDocumentAnnotations: [String] {
        [description]
    }
    @Published var documentIntegrators: Set<HashableDocumentIntegrator>

    @Published var calendars: Set<EKCalendar> = []
    var temporaryCalendarsIdentifiers: [String] = []

    var bookmarkFolder: URL? {
        configurationManager.documentFolderURL.appendingPathComponent(savedDescription)
    }

    init(_ description: String,
         _ configurationManager: ConfigurationManager,
         _ calendarResource: CalendarsResource,
         _ documentProcessorScript: URL? = nil,
         _ copyBeforeProcessing: Bool = true,
         _ removeOriginalOnProcessingByproduct: Bool = false,
         _ documentAnnotators: Set<HashableDocumentAnnotator> = [],
         _ documentIntegrators: Set<HashableDocumentIntegrator> = [],
         _ calendars: Set<EKCalendar> = []) {
        self.configurationManager = configurationManager
        self.description = description
        savedDescription = description
        self.documentProcessorScript = documentProcessorScript
        self.copyBeforeProcessing = copyBeforeProcessing
        self.removeOriginalOnProcessingByproduct = removeOriginalOnProcessingByproduct
        self.documentAnnotators = documentAnnotators
        self.documentIntegrators = documentIntegrators
        self.calendars = calendars

        subscriber = self.objectWillChange.sink {
            // Postpones call to wait for the object to actually change.
            DispatchQueue.main
                    .asyncAfter(deadline: .now() + .milliseconds(100)) {
                configurationManager.save(type: self)
            }
        }
        calendarResourceSubscriber = calendarResource.objectWillChange.sink { [self] in
            // Postpones call to wait for the object to actually change.
            DispatchQueue.main
                .asyncAfter(deadline: .now() + .milliseconds(100)) {
                if temporaryCalendarsIdentifiers.isEmpty {
                    // Filters the calendars if some have been removed by the user.
                    self.calendars = self.calendars.intersection(Set<EKCalendar>(calendarResource.calendars))
                } else {
                    // Registers the actual calendars using the provided calendar identifiers.
                    self.calendars = Set<EKCalendar>(calendarResource.calendars.filter {
                        temporaryCalendarsIdentifiers.contains($0.calendarIdentifier)
                    })
                    temporaryCalendarsIdentifiers = []
                }
            }
        }
    }
}

/// Implementation of a Partial Importation Configuration, presented to the user as `User Context`.
class UserContextMetadata: PartialImportationConfiguration, ObservableObject,
        CustomStringConvertible, Equatable, Identifiable {
    static func ==(lhs: UserContextMetadata, rhs: UserContextMetadata) -> Bool {
        lhs.description == rhs.description
    }

    private let configurationManager: ConfigurationManager
    private var subscriber: AnyCancellable!
    private var calendarResourceSubscriber: AnyCancellable!

    var savedDescription: String
    @Published var description: String
    @Published var documentAnnotators: Set<HashableDocumentAnnotator>
    var additionalDocumentAnnotations: [String] {
        [description]
    }
    @Published var documentIntegrators: Set<HashableDocumentIntegrator>

    @Published var calendars: Set<EKCalendar> = []
    var temporaryCalendarsIdentifiers: [String] = []

    init(_ description: String,
         _ configurationManager: ConfigurationManager,
         _ calendarResource: CalendarsResource,
         _ documentAnnotators: Set<HashableDocumentAnnotator> = [],
         _ documentIntegrators: Set<HashableDocumentIntegrator> = [],
         _ calendars: Set<EKCalendar> = []) {
        self.configurationManager = configurationManager
        self.description = description
        savedDescription = description
        self.documentAnnotators = documentAnnotators
        self.documentIntegrators = documentIntegrators
        self.calendars = calendars

        subscriber = self.objectWillChange.sink {
            // Postpones call to wait for the object to actually change.
            DispatchQueue.main
                    .asyncAfter(deadline: .now() + .milliseconds(100)) {
                configurationManager.saveContexts()
            }
        }
        calendarResourceSubscriber = calendarResource.objectWillChange.sink { [self] in
            // Postpones call to wait for the object to actually change.
            DispatchQueue.main
                .asyncAfter(deadline: .now() + .milliseconds(100)) {
                    if temporaryCalendarsIdentifiers.isEmpty {
                        // Filters the calendars if some have been removed by the user.
                        self.calendars = self.calendars.intersection(Set<EKCalendar>(calendarResource.calendars))
                    } else {
                        // Registers the actual calendars using the provided calendar identifiers.
                        self.calendars = Set<EKCalendar>(calendarResource.calendars.filter {
                            temporaryCalendarsIdentifiers.contains($0.calendarIdentifier)
                        })
                        temporaryCalendarsIdentifiers = []
                    }
                }
        }
    }
}

extension PicToShareError {
    static let configuration = PicToShareError(type: "pts.error.configuration")
}

/// Responsible of Core Objects configuration and storage.
class ConfigurationManager: ObservableObject {
    private let calendarResource: CalendarsResource
    /// List of available Document Annotators.
    var documentAnnotators: [HashableDocumentAnnotator]
    /// List of available Document Integrators.
    var documentIntegrators: [HashableDocumentIntegrator]

    /// URL of the main PTS folder.
    let documentFolderURL: URL
    /// URL of the folder where Continuity Camera Documents are saved.
    let continuityFolderURL: URL

    /// The configured Document Types.
    @Published var types: [DocumentTypeMetadata] = []

    /// The configured Importation Contexts.
    @Published var contexts: [UserContextMetadata] = []

    /// The User Context currently selected.
    private var currentContext_: UserContextMetadata? = nil
    var currentUserContext: UserContextMetadata? {
        get {
            currentContext_
        }
        set {
            currentContext_ = newValue
            // Saves the current User Context to persistent storage.
            setPreference("currentUserContext", (newValue?.description ?? "") as CFString)
            objectWillChange.send()
        }
    }

    /// Initializes the Configuration Manager with static parameters.
    ///
    /// - Parameters:
    ///   - ptsFolderName: Name for the main PicToShare folder.
    ///   - continuityFolderName: Name for the sub-folder where Continuity Camera Documents are saved.
    ///   - documentAnnotators: List of available Document Annotators.
    ///   - documentIntegrators: List of available Document Integrators.
    init(_ ptsFolderName: String,
         _ continuityFolderName: String,
         _ documentAnnotators: [DocumentAnnotator] = [],
         _ documentIntegrators: [DocumentIntegrator] = [],
         _ calendarResource: CalendarsResource) {
        self.documentAnnotators = documentAnnotators.map(HashableDocumentAnnotator.init)
        self.documentIntegrators = documentIntegrators.map(HashableDocumentIntegrator.init)
        self.calendarResource = calendarResource

        let userDocumentsURL = try! FileManager.default
                .url(for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
        documentFolderURL = userDocumentsURL
                .appendingPathComponent(ptsFolderName, isDirectory: true)
        continuityFolderURL = documentFolderURL
                .appendingPathComponent(continuityFolderName, isDirectory: true)
    }

    /// Configures a new Document Type.
    func addType(with description: String) {
        types.append(DocumentTypeMetadata(description, self, calendarResource))
        saveTypes()
    }

    func removeType(at index: Int) {
        types.remove(at: index)
        saveTypes()
    }

    /// Configures a new Importation Context.
    func addContext(with description: String) {
        contexts.append(UserContextMetadata(description, self, calendarResource))
        saveContexts()
    }

    func removeContext(at index: Int) {
        let context = contexts.remove(at: index)
        if currentUserContext == context {
            currentUserContext = nil
        }
        saveContexts()
    }
}

/// Methods responsible for the persistence of the Configuration.
///
/// Persistent storage is based on CFPreferences. Documents Types and User
/// Contexts are stored in two different keys, each with an array of
/// dictionaries (called declarations). The dictionaries hold data for all the
/// properties, converted to CRPropertyLists. In order to load the data, we need
/// to check the types of the values and cast them back to the appropriate type.
extension ConfigurationManager {
    /// Helper function to read data from key-value persistent storage.
    ///
    /// - Parameter key: The key of the value to read.
    /// - Returns: The value or nil if not found.
    private func getPreference(_ key: String) -> CFPropertyList? {
        CFPreferencesCopyAppValue(
                key as CFString,
                kCFPreferencesCurrentApplication)
    }

    /// Helper function to write data from key-value persistent storage.
    ///
    /// - Parameters:
    ///   - key: The key of the value to write.
    ///   - value: The value to write.
    private func setPreference(_ key: String, _ value: CFPropertyList) {
        CFPreferencesSetAppValue(
                key as CFString,
                value,
                kCFPreferencesCurrentApplication)
    }

    /// Configures Document Types by reading data from persistent storage.
    func loadTypes() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

        types.removeAll()
        /// The array of Type declarations.
        let typeDeclarations = getPreference("types")
                as? Array<CFPropertyList> ?? []
        for rawDeclaration in typeDeclarations {
            // Now we check the type of each value, ignoring the declaration if
            // it is invalid or using a default value.
            guard let declaration = rawDeclaration
                    as? Dictionary<String, Any> else {
                continue
            }

            guard let description = declaration["description"]
                    as? String else {
                continue
            }

            let documentProcessorScript: URL?
            if let scriptPath = declaration["documentProcessorScript"]
                    as? String {
                documentProcessorScript = URL(string: scriptPath)
            } else {
                documentProcessorScript = nil
            }

            let copyBeforeProcessing = declaration["copyBeforeProcessing"]
                    as? Bool ?? true

            let removeOriginalOnProcessingByproduct = declaration["removeOriginalOnProcessingByproduct"]
                    as? Bool ?? false

            var declaredAnnotators: Set<HashableDocumentAnnotator> = []
            let annotatorDeclarations = declaration["documentAnnotators"]
                    as? Array<CFPropertyList> ?? []
            for rawAnnotatorDeclaration in annotatorDeclarations {
                if let annotatorDescription = rawAnnotatorDeclaration
                        as? String,
                   let annotator = documentAnnotators
                           .first(where: { $0.description == annotatorDescription }) {
                    declaredAnnotators.insert(annotator)
                }
            }

            var declaredIntegrators: Set<HashableDocumentIntegrator> = []
            let integratorDeclarations = declaration["documentIntegrators"]
                    as? Array<CFPropertyList> ?? []
            for rawIntegratorDeclaration in integratorDeclarations {
                if let integratorDescription = rawIntegratorDeclaration
                        as? String,
                   let integrator = documentIntegrators
                           .first(where: { $0.description == integratorDescription }) {
                    declaredIntegrators.insert(integrator)
                }
            }

            let documentType = DocumentTypeMetadata(description,
                                                    self,
                                                    calendarResource,
                                                    documentProcessorScript,
                                                    copyBeforeProcessing,
                                                    removeOriginalOnProcessingByproduct,
                                                    declaredAnnotators,
                                                    declaredIntegrators)

            // The list of available calendars in the Calendar Resource may not
            // be up to date, and refreshing it is an asynchronous process, so
            // we just store the calendar identifiers in a temporary variable in
            // the Document Type. The next time calendars are updated, the Type
            // will register the actual calendars automatically.
            var calendarIdentifiers: [String] = []
            let calendarDeclarations = declaration["calendars"]
                as? Array<CFPropertyList> ?? []
            for rawCalendarDeclaration in calendarDeclarations {
                if let calendarDeclaration = rawCalendarDeclaration
                    as? String {
                    calendarIdentifiers.append(calendarDeclaration)
                }
            }
            documentType.temporaryCalendarsIdentifiers = calendarIdentifiers

            types.append(documentType)
        }
    }

    /// Configures Importation Contexts by reading data from persistent storage.
    func loadContexts() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

        contexts.removeAll()
        /// The array of Context declarations.
        let contextDeclarations = getPreference("contexts")
                as? Array<CFPropertyList> ?? []
        for rawDeclaration in contextDeclarations {
            // Now we check the type of each value, ignoring the declaration if
            // it is invalid or using a default value.
            guard let declaration = rawDeclaration
                    as? Dictionary<String, Any> else {
                continue
            }

            guard let description = declaration["description"]
                    as? String else {
                continue
            }

            var declaredAnnotators: Set<HashableDocumentAnnotator> = []
            let annotatorDeclarations = declaration["documentAnnotators"]
                    as? Array<CFPropertyList> ?? []
            for rawAnnotatorDeclaration in annotatorDeclarations {
                if let annotatorDescription = rawAnnotatorDeclaration
                        as? String,
                   let annotator = documentAnnotators
                           .first(where: { $0.description == annotatorDescription }) {
                    declaredAnnotators.insert(annotator)
                }
            }

            var declaredIntegrators: Set<HashableDocumentIntegrator> = []
            let integratorDeclarations = declaration["documentIntegrators"]
                    as? Array<CFPropertyList> ?? []
            for rawIntegratorDeclaration in integratorDeclarations {
                if let integratorDescription = rawIntegratorDeclaration
                        as? String,
                   let integrator = documentIntegrators
                           .first(where: { $0.description == integratorDescription }) {
                    declaredIntegrators.insert(integrator)
                }
            }

            let userContext = UserContextMetadata(description,
                                                 self,
                                                 calendarResource,
                                                 declaredAnnotators,
                                                 declaredIntegrators)

            // The list of available calendars in the Calendar Resource may not
            // be up to date, and refreshing it is an asyncronous process, so
            // we just store the calendar identifiers in a temporary variable in
            // the Document Type. The next time calendars are updated, the Type
            // will register the actual calendars automatically.
            var calendarIdentifiers: [String] = []
            let calendarDeclarations = declaration["calendars"]
                as? Array<CFPropertyList> ?? []
            for rawCalendarDeclaration in calendarDeclarations {
                if let calendarDeclaration = rawCalendarDeclaration
                    as? String {
                    calendarIdentifiers.append(calendarDeclaration)
                }
            }
            userContext.temporaryCalendarsIdentifiers = calendarIdentifiers

            contexts.append(userContext)
        }

        // Loads the current user context saved to persistent storage.
        if let savedCurrentContextDescription = getPreference("currentUserContext") as? String {
            currentUserContext = contexts.first {
                $0.description == savedCurrentContextDescription
            }
        }
    }

    /// Updates the folder corresponding to the given Document Type.
    /// Currently as multiple failing situations:
    /// - a file exists with the name of the document type;
    /// - the name of the document type contains forbidden characters for paths;
    /// - two document types have the same name.
    private func updateTypeFolder(_ type: DocumentTypeMetadata) {
        let newUrl = documentFolderURL.appendingPathComponent(type.description)
        let oldUrl = documentFolderURL.appendingPathComponent(type.savedDescription)
        if !FileManager.default.fileExists(atPath: oldUrl.path) {
            try! FileManager.default.createDirectory(at: newUrl, withIntermediateDirectories: true)
        } else {
            if type.savedDescription != type.description {
                do {
                    try FileManager.default.moveItem(at: oldUrl, to: newUrl)
                    type.savedDescription = type.description
                } catch {
                    type.description = type.savedDescription
                    ErrorManager.error(.configuration, String(format:
                    NSLocalizedString("pts.error.configuration.changeTypeDescription", comment: ""),
                            type.description))
                }
            }
        }
    }

    /// Saves the given Document Type to persistent storage
    func save(type: DocumentTypeMetadata) {
        updateTypeFolder(type)

        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    /// Saves all the configured Document Types.
    func saveTypes() {
        for type in types {
            updateTypeFolder(type)
        }
        setPreference("types",
                types.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    /// Saves all the configured Contexts.
    func saveContexts() {
        setPreference("contexts",
                contexts.map {
                    $0.toCFPropertyList()
                } as CFArray)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}

/// Utility to convert the object to a usable form for persistent storage.
extension DocumentTypeMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "documentProcessorScript": documentProcessorScript?.path ?? "",
            "copyBeforeProcessing": copyBeforeProcessing ?? true,
            "removeOriginalOnProcessingByproduct": removeOriginalOnProcessingByproduct ?? false,
            "documentAnnotators": documentAnnotators.map({ $0.description }) as CFArray,
            "documentIntegrators": documentIntegrators.map({ $0.description }) as CFArray,
            "calendars": calendars.map({ $0.calendarIdentifier }) as CFArray
        ] as CFPropertyList
    }
}

/// Utility to convert the object to a usable form for persistent storage.
extension UserContextMetadata: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        [
            "description": description,
            "documentAnnotators": documentAnnotators.map({ $0.description }) as CFArray,
            "documentIntegrators": documentIntegrators.map({ $0.description }) as CFArray,
            "calendars": calendars.map({ $0.calendarIdentifier }) as CFArray
        ] as CFPropertyList
    }
}
