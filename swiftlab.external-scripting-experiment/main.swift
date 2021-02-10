//
//  main.swift
//  swiftlab.external-scripting-experiment
//
//  Created by Guillaume Chauveau on 01/02/2021.
//

import Foundation
import PythonKit


class PythonModuleManager {
    static private let importlib = Python.import("importlib")
    static private let importlibUtil = Python.import("importlib.util")
    private struct Module {
        public let spec: PythonObject
        public var module: PythonObject?
    }
    private var modules = [String: Module]()

    public func reloadModule(name: String) {
        let spec = self.modules[name]!.spec
        let module = PythonModuleManager.importlibUtil.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.modules[name]!.module = module
    }

    public func loadModule(name: String, path: String) {
        let spec = PythonModuleManager.importlibUtil.spec_from_file_location(
            name, path)
        self.modules[name] = Module(spec: spec)
        self.reloadModule(name: name)
    }

    public subscript(name: String) -> PythonObject? {
        return self.modules[name]?.module
    }
}

let manager = PythonModuleManager()

class MyClass : PythonConvertible, ConvertibleFromPython {
    var data: String

    var pythonObject: PythonObject

    required init?(_ object: PythonObject) {
        self.data = String(object.string)!
        pythonObject = object
    }

    init(data: String) {
        self.data = data
        pythonObject = Python.getattr(manager["myscript"]!, "MyClass")(self.data)
    }

    func updateData() {
        self.pythonObject.updateData()
        self.data = String(self.pythonObject.string)!
    }
}

manager.loadModule(name: "myscript", path: "/Users/guillaumejchauveau/Documents/Projects/PicToShare/myscript.py")

var a = MyClass(data: "lol")
a.updateData()
a.updateData()
