import SwiftUI


/// Removes the focus ring on TextField.
extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get {
            .none
        }
        set {
        }
    }
}

/// A View that toggles the presence of an item in a set, using a Toggle.
struct SetItemToggleView<Item>: View where Item: CustomStringConvertible, Item: Hashable {
    /// The item.
    var item: Item
    /// The set to insert the item into.
    @Binding var selected: Set<Item>

    var body: some View {
        Toggle(item.description, isOn: Binding<Bool>(
                get: {
                    selected.contains(item)
                },
                set: {
                    if $0 {
                        selected.insert(item)
                    } else {
                        selected.remove(item)
                    }
                }
        ))
    }
}

/// A View that allows the user to select a set of items from a list.
struct SetOptionsView<Item>: View where Item: CustomStringConvertible, Item: Hashable {
    @Binding var options: [Item]
    @Binding var selected: Set<Item>

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(options, id: \.self) { item in
                SetItemToggleView(item: item, selected: $selected)
            }
        }
    }
}

