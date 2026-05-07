import Foundation
import UserNotifications

final class AlarmManager {
    static let shared = AlarmManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            print("Notifications granted: \(granted)")
        }
    }

    func schedule(_ alarm: Alarm) {
        guard alarm.isEnabled else {
            cancel(alarmID: alarm.id)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "Time to wake up"
        content.sound = .default

        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: alarm.repeatsDaily)
        let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule alarm \(alarm.id): \(error.localizedDescription)")
            }
        }
    }

    func cancel(alarmID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmID])
    }
}
