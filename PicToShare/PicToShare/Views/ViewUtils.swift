import SwiftUI

/// Button with the Accent Color as background.
///
/// Best-effort mimic of the original button style.
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        AccentButton(configuration: configuration)
    }

    struct AccentButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            configuration.label
                    .padding(EdgeInsets(top: 2,
                            leading: 7,
                            bottom: 2,
                            trailing: 7))
                    .background((isEnabled ?
                            Color.accentColor.opacity(colorScheme == .dark ?
                                    configuration.isPressed ? 0.9 : 0.75 :
                                    configuration.isPressed ? 1 : 0.9) :
                            colorScheme == .dark ? Color.gray : Color.white)
                            .cornerRadius(5)
                            .shadow(color: .gray,
                                    radius: colorScheme == .light ? 0.8 : 0,
                                    x: 0,
                                    y: colorScheme == .light ? 0.7 : 0))
                    .foregroundColor(colorScheme == .light && !isEnabled ? .gray : .white)
                    .opacity(isEnabled ? 1 : colorScheme == .dark ? 0.25 : 0.4)
        }
    }
}

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

struct SetItemToggleView<Item>: View where Item: CustomStringConvertible, Item: Hashable {
    @Binding var selected: Set<Item>
    var item: Item
    @State var state: Bool

    var body: some View {
        Toggle(item.description, isOn: Binding<Bool>(
                get: {
                    state
                },
                set: {
                    state = $0
                    if state {
                        selected.insert(item)
                    } else {
                        selected.remove(item)
                    }
                }
        ))
    }
}

struct SetGroupView<Label, Item>: View where Label: View, Item: CustomStringConvertible, Item: Hashable {
    var label: Label
    @Binding var available: Dictionary<String, Item>
    @Binding var selected: Set<Item>

    var body: some View {
        GroupBox(label: label) {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(available.values.map({ $0 }), id: \.self) { item in
                        SetItemToggleView(selected: $selected,
                                item: item,
                                state: selected.contains(item))
                    }
                }
                Spacer()
            }
        }
    }
}

