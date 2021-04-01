//
//  AppDelegate.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 01/04/2021.
//

import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var fsSource: FileSystemDocumentSource!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        fsSource = try! FileSystemDocumentSource(path: "PTSFolder")

        ConfigurationManager.shared.types.append(ConfigurationManager.DocumentTypeMetadata("Carte de visite"))
        ConfigurationManager.shared.types.append(ConfigurationManager.DocumentTypeMetadata("Affiche evenement"))
        ConfigurationManager.shared.types.append(ConfigurationManager.DocumentTypeMetadata("Tableau blanc"))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}


struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0

    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
            Slider(value: $fontSize, in: 9...96) {
                Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
            }
        }.padding(20)
    }
}

struct SettingsView: View {
    @ObservedObject var configurationManager: ConfigurationManager

    private enum Tabs: Hashable {
        case general, types
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            ConfigurationView(configurationManager: ConfigurationManager.shared)
                .tabItem {
                    Label("Types", systemImage: "doc.on.doc.fill")
                }
                .tag(Tabs.types)
        }
    }
}
