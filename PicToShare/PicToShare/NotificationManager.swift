import UserNotifications

class NotificationManager {
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

    func notifyUser(_ title: String, _ body: String, _ identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        center.add(request) { error in
            if error != nil {
                print(title)
                print(body)
            }
        }
    }

    private static var instance: NotificationManager? = nil

    static func notifyUser(_ title: String, _ body: String, _ identifier: String) {
        if instance == nil {
            instance = NotificationManager()
        }
        instance!.notifyUser(title, body, identifier)
    }
}
