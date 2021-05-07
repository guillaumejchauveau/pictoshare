//
//  ListSettingsView.swift
//  PicToShare
//
//  Created by Guillaume Chauveau on 07/05/2021.
//

import SwiftUI


struct ListSettingsView<Item, Content>: View where Item: CustomStringConvertible, Content: View {
    @State private var selection: Int? = nil
    @State private var showNewItemForm = false
    @State private var newItemDescription = ""

    @Binding var items: [Item]
    var add: (String) -> Void
    var remove: (Int) -> Void
    @ViewBuilder var content: (_ index: Int) -> Content

    var body: some View {
        VStack(alignment: .leading) {
            NavigationView {
                List(items.indices, id: \.self) { index in
                    NavigationLink(
                        destination: content(index),
                        tag: index,
                        selection: $selection) {
                        Text(items[index].description)
                    }
                }
            }.sheet(isPresented: $showNewItemForm) {
                Form {
                    TextField("Nom", text: $newItemDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Spacer(minLength: 50)
                        Button("Annuler") {
                            showNewItemForm = false
                            newItemDescription = ""
                        }
                        Button("Créer") {
                            add(newItemDescription)
                            selection = items.count - 1
                            showNewItemForm = false
                            newItemDescription = ""
                        }
                        .keyboardShortcut(.return)
                        .buttonStyle(AccentButtonStyle())
                        .disabled(newItemDescription.isEmpty)
                    }
                }.padding()
            }
            HStack {
                Button(action: { showNewItemForm = true }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    guard let index: Int = selection else {
                        return
                    }

                    if items.count == 1 {
                        selection = nil
                    } else if index != 0 {
                        selection! -= 1
                    }
                    // Workaround for a bug where the NavigationView won't clear the
                    // content of the destination view if we remove right after
                    // unselect.
                    DispatchQueue.main
                        .asyncAfter(deadline: .now() + .milliseconds(200)) {
                            if index < items.count {
                                remove(index)
                            }
                        }
                }) {
                    Image(systemName: "minus")
                }.disabled(selection == nil)
            }
            .buttonStyle(BorderedButtonStyle())
            .padding([.leading, .bottom, .trailing])
        }
    }
}
