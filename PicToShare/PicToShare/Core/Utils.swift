//
// Created by Guillaume Chauveau on 10/03/2021.
//

import SwiftUI

class SafePointer<T> {
    var pointee: T

    init(_ pointee: T) {
        self.pointee = pointee
    }
}

func makeSafe<T>(_ pointee: T) -> SafePointer<T> {
    SafePointer<T>(pointee)
}


protocol CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList
}

extension String: CFPropertyListable {
    func toCFPropertyList() -> CFPropertyList {
        self as CFPropertyList
    }
}