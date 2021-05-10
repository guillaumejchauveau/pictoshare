import UserNotifications

struct PicToShareError: Error {
    let type: String
}

class ErrorManager {
    private let center = UNUserNotificationCenter.current()

    private init() {
        let options = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)

        center.requestAuthorization(options: options) { success, error in
            guard error == nil else {
                print("Error in Notifications: \(error!)")
                return
            }
        }
    }

    private func notifyUser(_ title: String, _ body: String, _ identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        center.add(request) { error in
            if error != nil {
                print(title)
                print(body)
            }
        }
    }

    private static var instance: ErrorManager? = nil

    static func error(_ error: PicToShareError, key bodyKey: String) {
        Self.error(error, NSLocalizedString(bodyKey, comment: ""))
    }

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
