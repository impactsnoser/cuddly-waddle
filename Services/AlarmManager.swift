import Foundation
import UIKit
import UserNotifications

/// Показ баннера и звука, когда приложение на переднем плане.
private final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

final class AlarmManager {
    static let shared = AlarmManager()

    private let center = UNUserNotificationCenter.current()
    private let notificationDelegate = NotificationCenterDelegate()

    private init() {
        center.delegate = notificationDelegate
    }

    /// Синхронизация с системой: сначала статус разрешений, потом только реальное добавление триггеров.
    func syncSchedules(with alarms: [Alarm]) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            let enabledAlarms = alarms.filter(\.isEnabled)

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                enabledAlarms.forEach { self.schedulePending($0) }

            case .notDetermined:
                self.requestPermission { granted in
                    if granted {
                        enabledAlarms.forEach { self.schedulePending($0) }
                    }
                }

            case .denied:
                break

            @unknown default:
                break
            }
        }
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            print("Notifications granted: \(granted)")
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func schedule(_ alarm: Alarm) {
        guard alarm.isEnabled else {
            cancel(alarmID: alarm.id)
            return
        }

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.schedulePending(alarm)

            case .notDetermined:
                self.requestPermission { granted in
                    if granted {
                        self.schedulePending(alarm)
                    }
                }

            case .denied:
                print("Notifications denied: cannot schedule alarm \(alarm.id)")

            @unknown default:
                break
            }
        }
    }

    private func schedulePending(_ alarm: Alarm) {
        let content = UNMutableNotificationContent()
        let timeStr = String(format: "%02d:%02d", alarm.hour, alarm.minute)

        content.title = "⏰ \(alarm.title)"
        content.subtitle = "Время подъёма · \(timeStr)"
        content.body = Self.wakeUpMessages.randomElement() ?? "Пора вставать!"

        if let name = alarm.soundFileName, AlarmSoundStore.fileExists(name) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(name))
        } else {
            content.sound = .default
        }

        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: alarm.repeatsDaily)
        let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Failed to schedule alarm \(alarm.id): \(error.localizedDescription)")
            }
        }
    }

    func cancel(alarmID: String) {
        center.removePendingNotificationRequests(withIdentifiers: [alarmID])
    }

    private static let wakeUpMessages: [String] = [
        "Новый день зовёт — потягивайся и вставай ☀️",
        "Ты настроил будильник сам. Пора встречать утро!",
        "Кофе ждёт, мир не спит. Доброе утро!",
        "Ещё минута сна? Уже пора — вперёд!",
        "Солнце встаёт, и ты тоже. Хорошего дня!",
        "Мягкий подъём: глубокий вдох — и в ноги.",
    ]
}
