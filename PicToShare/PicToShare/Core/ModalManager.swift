import SwiftUI

/// Application manager facade responsible for displaying views for urgent user interactions.
///
/// Views are passed to this object using NSView instances, as the View protocol has an associated type.
class ModalManager: ObservableObject {
    static let instance = ModalManager()

    /// SwiftUI wrapper for NSView.
    struct ModalView: NSViewRepresentable {
        let content: NSView

        func makeNSView(context: Context) -> NSView {
            content
        }

        func updateNSView(_ nsView: NSView, context: Context) {

        }
    }

    /// Queue of pending modals.
    @Published private var queue: [NSView] = []

    static var isEmpty: Bool {
        instance.queue.isEmpty
    }

    /// Returns the first modal view in the queue.
    static var view: ModalView? {
        if let content = instance.queue.first {
            return ModalView(content: content)
        }
        return nil
    }

    static func queue<Content>(_ content: Content) where Content: View {
        instance.queue.append(NSHostingView(rootView: content))
    }

    static func queue(_ content: NSView) {
        instance.queue.append(content)
    }

    static func popQueueHead() {
        instance.queue.removeFirst()
    }
}
