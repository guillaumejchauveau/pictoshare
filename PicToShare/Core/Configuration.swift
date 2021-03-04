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

protocol IndexedKeyValueStore: KeyValueStore {
    func getIndexes(at key: String) throws -> Set<Int>
}

class CFPreferencesKeyValueStore: IndexedKeyValueStore {
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
            CFPreferencesSetValue(
                    root + key as CFString,
                    newValue as CFPropertyList,
                    kCFPreferencesCurrentApplication,
                    kCFPreferencesCurrentUser,
                    kCFPreferencesCurrentHost)
        }
    }

    func getIndexes(at key: String) throws -> Set<Int> {
        let keys = CFPreferencesCopyKeyList(
                kCFPreferencesCurrentApplication,
                kCFPreferencesCurrentUser,
                kCFPreferencesCurrentHost) as [CFPropertyList]? ?? []

        do {
            let pattern = try NSRegularExpression(pattern: key + "([0-9]+)[^0-9]")
            return Set(keys.map { key_ -> Int? in
                if let key = key_ as? String {
                    if let match = pattern.firstMatch(in: key, range: NSRange(location: 0, length: key.count)) {
                        return Int(key[Range(match.range(at: 1), in: key)!])
                    }
                }
                return nil
            }.compactMap {
                $0
            })
        } catch {
            throw error
        }
    }
}


struct DocumentSourceConfiguration {
    var classID: ClassID
    var description: String
    var configuration: Dictionary<String, CFPropertyList>
}

struct DocumentAnnotatorConfiguration {
    var classID: ClassID
    var configuration: Dictionary<String, CFPropertyList>
}

struct DocumentTypeConfiguration {
    var format: ClassID
    var description: String
    var annotators: [DocumentAnnotatorConfiguration]
}


class ConfigurationManager {
    private var preferencesStore = CFPreferencesKeyValueStore()

    subscript(class id: ClassID) -> Dictionary<String, CFPropertyList>? {
        get {
            preferencesStore[id] as? Dictionary<String, CFPropertyList>
        }

        set {
            preferencesStore[id] = newValue
        }
    }

    func save() {

    }

}


class ConfigurationGroup {
    private let pathTemplate: String
    private var store: KeyValueStore

    var pathTemplateVars: Dictionary<String, CVarArg> = [:]

    init(pathTemplate: String, store: KeyValueStore) {
        self.pathTemplate = pathTemplate
        self.store = store
    }

    private var groupPath: String {
        String(format: pathTemplate, arguments: Array(pathTemplateVars.values))
    }

    subscript(key: String) -> Any? {
        get {
            store[groupPath + key]
        }
        set {
            store[groupPath + key] = newValue
        }
    }
}

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
