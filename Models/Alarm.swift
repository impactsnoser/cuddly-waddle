import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: String
    var hour: Int
    var minute: Int
    var title: String
    var isEnabled: Bool
    var repeatsDaily: Bool
    /// Имя файла в `Library/Sounds` (wav/caf). `nil` — системный звук уведомления.
    var soundFileName: String?

    init(
        id: String = UUID().uuidString,
        hour: Int,
        minute: Int,
        title: String = "Brudilnik",
        isEnabled: Bool = true,
        repeatsDaily: Bool = true,
        soundFileName: String? = nil
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.title = title
        self.isEnabled = isEnabled
        self.repeatsDaily = repeatsDaily
        self.soundFileName = soundFileName
    }

    var timeLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }
}
