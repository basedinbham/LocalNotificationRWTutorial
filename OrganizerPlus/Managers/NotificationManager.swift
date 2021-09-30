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

import Foundation
import UserNotifications
import CoreLocation

enum NotificationManagerConstants {
  static let timeBasedNotificationThreadId = "TimeBasedNotificationThreadId"
  static let calendarBasedNotificationThreadId = "CalendarBasedNotificationThreadId"
  static let locationBasedNotificationThreadId = "LocationBasedNotificationThreadId"
}

class NotificationManager: ObservableObject {
  static let shared = NotificationManager()
  @Published var settings: UNNotificationSettings?
  
  func requestAuthorization(completion: @escaping (Bool) -> Void) {
    // Handles all notification behavior in app (requesting auth, scheduling delivery, & handling actions). current() is shared instance
    UNUserNotificationCenter.current()
      // Request auth to show notif.; options denotes notif behavior (displaying alert, playing sound, badge)
      .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        // fetch notif settings after user grants auth
        self.fetchNotificationSettings()
        // Completion handler receives boolean indicating whether user granted auth; call completion handler with boolean value
        completion(granted)
      }
  }
  
  func fetchNotificationSettings() {
    // 1 requests notification settings auth'd by app. Settings return async; UNNotifSet. manages notif related settings and auth status of app. settings is an instance of it
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      // 2 Completion block may be called on background thread; here we update settings property on main thread as chaning its value updates UI
      DispatchQueue.main.async {
        self.settings = settings
      }
    }
  }
  
  // 1 takes in parameter of type task (model) whoich holds all data related to any task
  func scheduleNotification(task: Task) {
    // 2 You start by creating notification by populating notif content. UNMutNotifCont holds payload for local notif. Here, we populate title and body of notif
    let content = UNMutableNotificationContent()
    content.title = task.name
    content.body = "Gentle reminder for your task!"
    // Notifications content categoryIdentifier set to ident. used when UNNotifCat was instantiated
    content.categoryIdentifier = "OrganizerPlusCategory"
    // Encode the task data & assign it to notif content userInfo. This allows the app to access this content when user acts on notification
    let taskData = try? JSONEncoder().encode(task)
    if let taskData = taskData {
      content.userInfo = ["Task": taskData]
    }
    
    // 3 Abstract class that triggers delivery of notif. We check if reminderType of task is time based with valid time interval. Next, we create time-interval based notif trigger using UNTimeIntNotifTrigger. We use this type of trigger to schedule timers. Constructor also takes in boolean parameter (repeats) this determines whether the notification needs to resched after being delivered.
    var trigger: UNNotificationTrigger?
    switch task.reminder.reminderType {
    case .time:
      if let timeInterval = task.reminder.timeInterval {
        trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: task.reminder.repeats)
      }
      // 1 Check if reminder of task has a date set
      // 2 Create notification trigger of type UNCalNotifTrigger. The calendar trigger delivers a notification based on a particular date and time. It extracts dateComponents from the date user selected. Specifying only the time components will trigger a notification at specified time.
      content.threadIdentifier = NotificationManagerConstants.timeBasedNotificationThreadId
    case .calendar:
      if let date = task.reminder.date {
        trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: date), repeats: task.reminder.repeats)
      }
      content.threadIdentifier = NotificationManagerConstants.calendarBasedNotificationThreadId
    case .location:
      // 1 Check if user has granted when in use location auth
      guard CLLocationManager().authorizationStatus == .authorizedWhenInUse else { return }
      
      // 2 Ensure locaiton data exists for task reminder
      if let location = task.reminder.location {
        // 3 Create location based trigger using UNLocNotifTrigger. Firstm define center by CLLocCoord2D. With this, we create an instance of CLCircRegion  by specifying radius and unique ID. Last, we create trigger using circular region.
        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = CLCircularRegion(center: center, radius: location.radius, identifier: task.id)
        trigger = UNLocationNotificationTrigger(region: region, repeats: task.reminder.repeats)
      }
      content.threadIdentifier = NotificationManagerConstants.locationBasedNotificationThreadId
    }
    
    // 4 After trigger definition, next step is to create notif request. We create new request using UNNotifReq and specify an identifier, content, & trigger. Each task has a unique identifier. We pass that as notif identifier
    if let trigger = trigger {
      let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
      
      // 5 Schedule notif by adding request to UNUserNotifCenter. Completion handler as error object that indicates if problem occurs when scheduling notif
      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          print(error)
        }
      }
    }
  }
  
  // Ensure removal of pending notif up on task completion. We pass identififer of task in an arry. This is very useful for tasks that have repeats set to true
  func removeScheduledNotification(task: Task) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [task.id])
  }
  
} // End of Class
