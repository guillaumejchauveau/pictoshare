import SwiftUI

/// A View that allows the user navigate in a list of items, and add or remove
/// items.
struct ListSettingsView<Item, Landing, Content>: View
        where Item: CustomStringConvertible, Landing: View, Content: View {
    @State private var selection: Int? = nil
    @State private var showNewItemForm = false
    @State private var newItemDescription = ""
    @State private var showConfirmItemDeletion = false
    @State private var confirmItemDeletionIndex: Int? = nil

    /// The list of items.
    @Binding var items: [Item]
    /// Callback for adding a new item, using a description.
    var add: (String) -> Void
    /// Callback for removing an item at a given index.
    var remove: (Int) -> Void
    /// Landing View displayed when no items are selected.
    var landing: Landing
    /// View builder taking the index of the selected item.
    @ViewBuilder var content: (Int) -> Content

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
                landing
            }.sheet(isPresented: $showNewItemForm) {
                // New item form.
                Form {
                    TextField("name", text: $newItemDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Spacer(minLength: 50)
                        Button("cancel") {
                            showNewItemForm = false
                            newItemDescription = ""
                        }.keyboardShortcut(.cancelAction)
                        Button("create") {
                            add(newItemDescription)
                            selection = items.count - 1
                            showNewItemForm = false
                            newItemDescription = ""
                        }
                                .keyboardShortcut(.defaultAction)
                                .disabled(newItemDescription.isEmpty)
                    }
                }.padding()
            }
            HStack {
                // Add item button.
                Button(action: { showNewItemForm = true }) {
                    Image(systemName: "plus")
                }
                // Remove item button.
                Button(action: {
                    guard let index = selection else {
                        return
                    }
                    confirmItemDeletionIndex = index
                    showConfirmItemDeletion = true
                }) {
                    Image(systemName: "minus")
                }.disabled(selection == nil)
                        .alert(isPresented: $showConfirmItemDeletion) {
                            Alert(
                                    title: Text("confirm.delete"),
                                    message: Text("operation.irreversible"),
                                    primaryButton: .destructive(Text("delete")) {
                                        guard let index = confirmItemDeletionIndex else {
                                            return
                                        }
                                        confirmItemDeletionIndex = nil
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
                                    },
                                    secondaryButton: .cancel())
                        }
            }
                    .buttonStyle(BorderedButtonStyle())
                    .padding([.leading, .bottom, .trailing])
        }
    }
}
