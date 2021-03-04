//
//  Main.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 25/02/2021.
//

import SwiftUI
import CoreFoundation

/*let delegate = AppDelegate()
NSApplication.shared.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)*/


/**
 core/...
 standard.exporter.pdf
 sources/0/description
 sources/0/classID
 sources/0/configuration
 types/0/description
 types/0/format
 types/0/annotators/0/classID
 types/0/annotators/0/configuration
 types/0/exporter/classID
 types/0/exporter/configuration
 */
/*
var preferencesStore = CFPreferencesKeyValueStore()
var defaultGroup = ConfigurationGroup(pathTemplate: "", store: [
    "test": 2
])
var classGroup = ConfigurationGroup(pathTemplate: "standard.sources.filesystem/", store: preferencesStore)
var instanceGroup = ConfigurationGroup(pathTemplate: "sources/%d/configuration/", store: preferencesStore)
instanceGroup.pathTemplateVars["index"] = 0
instanceGroup["test"] = 5

var view = ConfigurationView()
view.groups = [defaultGroup, classGroup, instanceGroup]

print(CFPreferencesCopyAppValue("sources/0/configuration/test" as CFString, kCFPreferencesCurrentApplication))
*/
var preferencesStore = CFPreferencesKeyValueStore()
var s = DocumentSourceConfiguration("standard.sources.fs")
s.description = "File system"
s.configuration["a"] = 6 as CFPropertyList

preferencesStore["sources"] = [
    s.toCFPropertyList()
]

/*preferencesStore["sources"] = [
    [
        "classID": "standard.sources.fs",
        "description": "File system",
        "configuration": [
            "a": 5
        ]
    ]
]*/

guard let sources = preferencesStore["sources"] as? Array<CFPropertyList> else {
    fatalError()
}

let source = try DocumentSourceConfiguration(data: sources[0])
print(source)