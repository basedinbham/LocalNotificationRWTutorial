/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Calling configUserNotif to set notification delegate as soon as app launches
    configureUserNotifications()
    return true
  }
}

//MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  // asks delegate how to handle notif when app is in foreground. We call completion handler with the presentation option set to banner.
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
    completionHandler(.banner)
  }
  
  // We declare configureNotif whcih makes Appdelegate the delegate for UNUserNotificationCenter
  private func configureUserNotifications() {
    UNUserNotificationCenter.current().delegate = self
    // 1 disiss, & markdone actions added. These display as action buttons with notification. Each instance of UNNotifAction has identifier, title, & array of options. Identifier uniquely identifes the action. Title represents the text on bugtton; options denotes the behavior associated with action.
    let dismissAction = UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [])
    let markAsDone = UNNotificationAction(identifier: "markAsDone", title: "Mark As Done", options: [])
    // 2 Define notif cat. UNNotifCat defindes type of notif app can receive. identifier uniquely identifies the category. intentIdentifiers let system know that notif relates to request made by Siri. The options denote how to handle the notif associated with them.
    let category = UNNotificationCategory(identifier: "OrganizerPlusCategory", actions: [dismissAction, markAsDone], intentIdentifiers: [], options: [])
    // 3 Register new actionable notification.
    UNUserNotificationCenter.current().setNotificationCategories([category])
  }
  
  // 1 iOS calls func when user acts on notif
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // 2 Check if the response's actionIdentifier is set to markAsDone. Then, decode the task from userInfo
    if response.actionIdentifier == "markAsDone" {
      let userInfo = response.notification.request.content.userInfo
      if let taskData = userInfo["Task"] as? Data {
        if let task = try? JSONDecoder().decode(Task.self, from: taskData) {
          // 3 After decode succeeds, remove task using the shared instance of TaskManager
          TaskManager.shared.remove(task: task)
        }
      }
    }
    completionHandler()
  }
} // End of Extension

