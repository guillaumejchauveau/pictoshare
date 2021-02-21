//
//  ContentView.swift
//  PicToShare Dock
//
//  Created by Anaïs on 18/02/2021.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


func dockMenu() {

}


class NSMenu : NSObject{
    
    var String p "Paramètres"
    var String i "Importer"
    var String q "Quitter"
    
    // Indicates the currently highlighted item in the menu.
    var highlightedItem: NSMenuItem?
    
    // Initializes and returns a menu having the specified title and with autoenabling of menu items turned on.
    init(title: String){
        let title = "Paramètres"
    }
    
    init(title: String){
        let title = "Importer"
    }
    
    init(title: String){
        let title = "Quitter"
    }
    
    // Creates a new menu item and adds it to the end of the menu.
    // Adds Paramètres menu line
    func addItem(withTitle: String, action: Selector?, keyEquivalent: String) -> NSMenuItem {
        return NSMenuItem(title: withTitle, action: action, keyEquivalent: keyEquivalent)
    }
    
    
    
    
    //Causes the application to send the action message of a specified menu item to its target.
    func performActionForItem(at: 1){
        
    }

    
    func addItem("Importer", action: Selector?, " ") -> NSMenuItem{
        
    }
    
    
    func addItem(Quitter: String, action: Selector?, keyEquivalent: String) -> NSMenuItem{
        
    }
}

// Assigns a menu to be a submenu of the menu controlled by a given menu item.
func setSubmenu(NSMenu?, for: NSMenuItem)

// The parent menu that contains the menu as a submenu.
var supermenu: NSMenu?
