//
// Created by Guillaume Chauveau on 10/03/2021.
//

import CoreFoundation

class DictionaryRef<Key, Value> where Key: Hashable {
    var dictionary: Dictionary<Key, Value>

    init(_ dictionary: Dictionary<Key, Value>) {
        self.dictionary = dictionary
    }

    subscript(key: Key) -> Value? {
        get {
            dictionary[key]
        }

        set {
            dictionary[key] = newValue
        }
    }

    func removeAll() {
        dictionary.removeAll()
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

extension DictionaryRef: CFPropertyListable where Key == String {
    func toCFPropertyList() -> CFPropertyList {
        dictionary as CFPropertyList
    }
}
