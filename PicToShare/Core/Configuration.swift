//
//  Configuration.swift
//  PicToShare/Core
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import Foundation

protocol KeyValueStore {
    subscript(_ key: String) -> Any? { get set }
}

extension Dictionary: KeyValueStore where Key == String, Value == Any {
}

class CFPreferencesKeyValueStore: KeyValueStore {
    private let root: String

    init(root: String = "") {
        self.root = root
    }

    subscript(key: String) -> Any? {
        get {
            CFPreferencesCopyAppValue(
                    root + key as CFString,
                    kCFPreferencesCurrentApplication)
        }
        set {
            CFPreferencesSetAppValue(
                    root + key as CFString,
                    newValue as CFPropertyList,
                    kCFPreferencesCurrentApplication)
        }
    }
}

protocol CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList
}

extension String: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        self as CFPropertyList
    }
}


struct DocumentSourceConfiguration: CFPropertyListable {
    var classID: ClassID
    var description: String = ""
    var configuration: Dictionary<String, CFPropertyList> = [:]

    init(_ classID: ClassID) {
        self.classID = classID
    }

    init(data: CFPropertyList) throws {
        guard let dictionary = data as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        guard let classID = dictionary["classID"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.classID = classID
        guard let description = dictionary["description"] as? String else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.description = description
        guard let configuration = dictionary["configuration"] as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.configuration = configuration
    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "classID": classID,
            "description": description,
            "configuration": configuration
        ] as CFPropertyList
    }
}

struct DocumentAnnotatorConfiguration {
    var classID: ClassID
    var configuration: Dictionary<String, CFPropertyList> = [:]

    init(_ classID: ClassID) {
        self.classID = classID
    }

    init(data: CFPropertyList) throws {
        guard let dictionary = data as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        guard let classID = dictionary["classID"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.classID = classID
        guard let configuration = dictionary["configuration"] as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.configuration = configuration

    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "classID": classID,
            "configuration": configuration
        ] as CFPropertyList
    }
}

struct DocumentTypeConfiguration {
    var format: ClassID
    var description: String = ""
    var annotators: [DocumentAnnotatorConfiguration] = []
    var exporter: ClassID
    var exporterConfiguration: Dictionary<String, CFPropertyList> = [:]

    init(_ format: ClassID, _ exporter: ClassID) {
        self.format = format
        self.exporter = exporter
    }

    init(data: CFPropertyList) throws {
        guard let dictionary = data as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        guard let format = dictionary["format"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.format = format
        guard let description = dictionary["description"] as? String else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.description = description
        guard let annotators = dictionary["annotators"] as? Array<CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        for annotator in annotators {
            do {
                self.annotators.append(try DocumentAnnotatorConfiguration(data: annotator))
            } catch {
                continue
            }
        }
        guard let exporter = dictionary["exporter"] as? ClassID else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.exporter = exporter
        guard let exporterConfiguration = dictionary["exporterConfiguration"] as? Dictionary<String, CFPropertyList> else {
            throw ConfigurationManager.Error.preferencesError
        }
        self.exporterConfiguration = exporterConfiguration

    }

    func toCFPropertyList() -> CFPropertyList {
        [
            "format": format,
            "description": description,
            "annotators": annotators.map { annotator -> CFPropertyList in
                annotator.toCFPropertyList()
            }
        ] as CFPropertyList
    }
}


class ConfigurationManager {
    enum Error: Swift.Error {
        case preferencesError
    }

    private var preferencesStore = CFPreferencesKeyValueStore()
    var sources: [DocumentSourceConfiguration] = []
    var types: [DocumentTypeConfiguration] = []

    init() {
        let sources = preferencesStore["sources"] as? Array<CFPropertyList> ?? []
        for source in sources {
            do {
                self.sources.append(try DocumentSourceConfiguration(data: source))
            } catch {
                continue
            }
        }
        let types = preferencesStore["types"] as? Array<CFPropertyList> ?? []
        for type in types {
            do {
                self.types.append(try DocumentTypeConfiguration(data: type))
            } catch {
                continue
            }
        }
    }

    subscript(class id: ClassID) -> Dictionary<String, CFPropertyList>? {
        get { // TODO: Lazy load and store.
            preferencesStore[id] as? Dictionary<String, CFPropertyList>
        }

        set {
            preferencesStore[id] = newValue
        }
    }

    func save() {
        preferencesStore["sources"] = sources.map { $0.toCFPropertyList() }
        preferencesStore["types"] = types.map { $0.toCFPropertyList() }
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

}


// Make somehow a reference to the right dictionaries.
class ConfigurationView {
    var groups: [ConfigurationGroup] = []

    subscript(key: String) -> Any? {
        get {
            for group in groups.reversed() {
                let value = group[key]
                if (value != nil) {
                    return value
                }
            }
            return nil
        }
    }

}

/*class Configuration {
    private let view: ConfigurationView

    init(view: ConfigurationView) {
        self.view = view
    }

    subscript(key: String) -> Any? {
        get {
            view[key]
        }
    }
}*/
typealias Configuration = Dictionary<String, String>
