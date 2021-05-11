import UserNotifications

/// Holds information for reporting errors to the user.
struct PicToShareError: Error {
    /// Identifies the error for notifications and generating localized string
    /// as title.
    let type: String
}

/// Application manager facade responsible for reporting errors to the user.
class ErrorManager {
    private let center = UNUserNotificationCenter.current()

    private init() {
        let options = UNAuthorizationOptions.init(
                arrayLiteral: .alert, .badge, .sound)

        center.requestAuthorization(options: options) { success, error in
            guard error == nil else {
                print("Error in Notifications: \(error!)")
                return
            }
        }
    }

    /// Shows an error notification to the user.
    private func notifyUser(
            _ title: String,
            _ body: String,
            _ identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil)

        center.add(request) { error in
            if error != nil {
                print(title)
                print(body)
            }
        }
    }

    /// Singleton instance.
    private static var instance: ErrorManager? = nil

    /// Facade for reporting an error using a localized string key.
    static func error(_ error: PicToShareError, key bodyKey: String) {
        Self.error(error, NSLocalizedString(bodyKey, comment: ""))
    }

    /// Facade for reporting an error with a message.
    static func error(_ error: PicToShareError, _ body: String) {
        if instance == nil {
            instance = ErrorManager()
        }
        instance!.notifyUser(
                NSLocalizedString(error.type, comment: ""),
                body,
                error.type)
    }
}
