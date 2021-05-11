import AppKit

/// Delegate for the PicToShare status item menu.
class StatusMenuDelegate: NSObject, NSMenuDelegate {
    private let configurationManager: ConfigurationManager

    init(_ configurationManager: ConfigurationManager, _ menu: NSMenu) {
        self.configurationManager = configurationManager
        super.init()
        // Ensures state column used to show the current user context.
        menu.showsStateColumn = true
        // Open PTS item.
        menu.addItem(withTitle: NSLocalizedString("pts.open", comment: ""),
                action: #selector(openPTS),
                keyEquivalent: "")
                .target = self
        // Open PTS folder item.
        menu.addItem(withTitle: NSLocalizedString("pts.openPTSFolder", comment: ""),
                action: #selector(openFolderInFinder),
                keyEquivalent: "")
                .target = self
        menu.addItem(NSMenuItem.separator())

        menu.delegate = self
    }

    /// Called every time the menu will open. Used to update the list of user
    /// contexts.
    func menuWillOpen(_ menu: NSMenu) {
        // Removes the previous list.
        while menu.numberOfItems > 3 {
            menu.removeItem(at: 3)
        }

        let current = configurationManager.currentUserContext

        // Creates a list of contexts including the nil context.
        var contexts: [UserContextMetadata?] = [nil]
        contexts.append(contentsOf: configurationManager.contexts)

        for context in contexts {
            let item = menu.addItem(
                    withTitle: context?.description ?? NSLocalizedString("pts.userContext.nil", comment: ""),
                    action: #selector(selectUserContext), keyEquivalent: "")
            item.target = self
            item.state = current == context ? .on : .off
            item.representedObject = context
        }
    }

    @objc func openPTS(_ sender: Any) {
        PTSApp.openPTS()
    }

    @objc func openFolderInFinder(_ sender: Any) {
        NSWorkspace.shared.open(configurationManager.documentFolderURL)
    }

    /// User context item callback.
    @objc func selectUserContext(_ sender: Any) {
        guard let item = sender as? NSMenuItem,
              let context = item.representedObject as? UserContextMetadata? else {
            return
        }
        configurationManager.currentUserContext = context
    }
}
