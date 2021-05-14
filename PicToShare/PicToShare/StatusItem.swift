import AppKit

/// Delegate for the PicToShare status item menu.
class StatusMenuDelegate: NSObject, NSMenuDelegate {
    private let configurationManager: ConfigurationManager
    private let userContextsStartItem = NSMenuItem.separator()
    private let userContextsEndItem = NSMenuItem.separator()

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
        menu.addItem(userContextsStartItem)
        // Between those items will be the user contexts.
        menu.addItem(userContextsEndItem)
        // Quit PTS.
        menu.addItem(withTitle: NSLocalizedString("pts.quit", comment: ""),
                action: #selector(quitPTS),
                keyEquivalent: "")
                .target = self

        menu.delegate = self
    }

    /// Called every time the menu will open. Used to update the list of user
    /// contexts.
    func menuWillOpen(_ menu: NSMenu) {
        let userContextsFirstItemIndex = menu.index(of: userContextsStartItem) + 1
        // Empties the list.
        var removingItem: NSMenuItem? = menu.item(at: userContextsFirstItemIndex)
        while removingItem != userContextsEndItem && removingItem != nil {
            menu.removeItem(removingItem!)
            removingItem = menu.item(at: userContextsFirstItemIndex)
        }

        let current = configurationManager.currentUserContext

        // Creates a list of contexts including the nil context.
        var contexts: [UserContextMetadata?] = [nil]
        contexts.append(contentsOf: configurationManager.contexts)

        var insertIndex = userContextsFirstItemIndex
        for context in contexts {
            let item = menu.insertItem(
                    withTitle: context?.description ?? NSLocalizedString("pts.userContext.nil", comment: ""),
                    action: #selector(selectUserContext), keyEquivalent: "",
                    at: insertIndex)
            item.target = self
            item.state = current == context ? .on : .off
            item.representedObject = context
            insertIndex += 1
        }
    }

    @objc func openPTS(_ sender: Any) {
        PTSApp.openPTS()
    }

    @objc func quitPTS(_ sender: Any) {
        PTSApp.quitPTS()
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
