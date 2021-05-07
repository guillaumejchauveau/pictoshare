//
//  NotificationManager.swift
//  PicToShare
//
//  Created by Steven on 07/05/2021.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let center = UNUserNotificationCenter.current()
    
    init() {
        requestNotificationAuthorization()
    }
    
    private func requestNotificationAuthorization() {
        let options = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
            
        NotificationManager.center.requestAuthorization(options: options) { success, error in
            if let error = error {
                print("Error in Notifications: \(error)")
            }
        }
    }
    
    static func notifyUser(_ title: String, _ body: String, _ identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        center.add(request, withCompletionHandler: nil)
    }
}
