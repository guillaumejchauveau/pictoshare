import AppKit

class StatusMenuDelegate: NSObject, NSMenuDelegate {
    private let configurationManager: ConfigurationManager

    init(_ configurationManager: ConfigurationManager, _ menu: NSMenu) {
        self.configurationManager = configurationManager
        super.init()
        menu.showsStateColumn = true
        menu.addItem(withTitle: NSLocalizedString("pts.open", comment: ""),
                action: #selector(openPTS),
                keyEquivalent: "")
                .target = self
        menu.addItem(withTitle: NSLocalizedString("pts.openPTSFolder", comment: ""),
                action: #selector(openFolderInFinder),
                keyEquivalent: "")
                .target = self
        menu.addItem(NSMenuItem.separator())
        menu.delegate = self
        menu.autoenablesItems = true
    }

    func menuWillOpen(_ menu: NSMenu) {
        while menu.numberOfItems > 3 {
            menu.removeItem(at: 3)
        }

        let current = configurationManager.currentUserContext

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
        PTSApp.openPTSUrl()
    }

    @objc func openFolderInFinder(_ sender: Any) {
        NSWorkspace.shared.open(configurationManager.documentFolderURL)
    }

    @objc func selectUserContext(_ sender: Any) {
        guard let item = sender as? NSMenuItem,
              let context = item.representedObject as? UserContextMetadata? else {
            return
        }
        configurationManager.currentUserContext = context
    }
}
