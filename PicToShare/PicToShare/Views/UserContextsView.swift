import SwiftUI
import EventKit

/// View for editing User Contexts in the settings.
struct UserContextsView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager

    struct Landing: View {
        var body: some View {
            ZStack {
                Image(systemName: "questionmark.circle").imageScale(.large)
                        .font(.system(size: 30))
                        .offset(y: -80)
                Text("pts.settings.userContexts.landing")
                        .font(.system(size: 16, weight: .light)).lineSpacing(5)
            }.frame(width: 400)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Uses a custom View to make a Navigation View with all the Contexts.
            ListSettingsView(items: $configurationManager.contexts,
                    add: configurationManager.addContext,
                    remove: configurationManager.removeContext,
                    landing: Landing()) { index in
                UserContextView(
                        description: $configurationManager.contexts[index].description,
                        documentAnnotators: $configurationManager.contexts[index].documentAnnotators,
                        documentIntegrators: $configurationManager.contexts[index].documentIntegrators,
                        calendars: $configurationManager.contexts[index].calendars,
                        editingDescription: configurationManager.contexts[index].description)
            }
        }
    }
}


/// A View for editing a User Context.
struct UserContextView: View {
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var calendarResource: CalendarsResource

    @Binding var description: String
    @Binding var documentAnnotators: Set<HashableDocumentAnnotator>
    @Binding var documentIntegrators: Set<HashableDocumentIntegrator>
    @Binding var calendars: Set<EKCalendar>

    @State var editingDescription: String

    private func validateDescription() {
        if editingDescription.isEmpty {
            NSSound.beep()
            return
        }
        description = editingDescription
    }

    var body: some View {
        ScrollView {
            Form {
                GroupBox(label: Text("name")) {
                    HStack {
                        TextField("", text: $editingDescription, onCommit: validateDescription)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(2)
                        Spacer()
                        Button(action: validateDescription) {
                            Image(systemName: "checkmark")
                        }.disabled(description == editingDescription)
                    }
                }

                GroupBox(label: Text("pts.annotations")) {
                    HStack {
                        SetOptionsView(
                                options: $configurationManager.documentAnnotators,
                                selected: $documentAnnotators)
                        Spacer()
                    }
                }

                GroupBox(label: Text("pts.integrations")) {
                    HStack {
                        SetOptionsView(
                                options: $configurationManager.documentIntegrators,
                                selected: $documentIntegrators)
                        Spacer()
                    }
                }

                GroupBox(label: Text("pts.resources.calendars")) {
                    HStack {
                        VStack(alignment: .leading) {
                            SetOptionsView(
                                    options: $calendarResource.calendars,
                                    selected: $calendars
                            ).padding(.bottom, 5)

                            HStack {
                                Button(action: calendarResource.refreshCalendars) {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("refresh")
                            }
                        }
                        Spacer()
                    }
                }
            }.padding()
        }
    }
}
