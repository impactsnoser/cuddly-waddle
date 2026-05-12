import Foundation

final class AlarmListViewModel: ObservableObject {
    @Published private(set) var alarms: [Alarm] = []

    private let storageKey = "alarms_storage_v1"

    init() {
        load()
        AlarmManager.shared.syncSchedules(with: alarms)
    }

    func addAlarm(hour: Int, minute: Int, title: String, repeatsDaily: Bool, soundFileName: String? = nil) {
        let alarm = Alarm(hour: hour, minute: minute, title: title, repeatsDaily: repeatsDaily, soundFileName: soundFileName)
        alarms.append(alarm)
        AlarmManager.shared.schedule(alarm)
        save()
    }

    func setEnabled(_ isEnabled: Bool, for alarmID: String) {
        guard let index = alarms.firstIndex(where: { $0.id == alarmID }) else { return }
        alarms[index].isEnabled = isEnabled
        let alarm = alarms[index]
        if isEnabled {
            AlarmManager.shared.schedule(alarm)
        } else {
            AlarmManager.shared.cancel(alarmID: alarm.id)
        }
        save()
    }

    func deleteAlarm(at offsets: IndexSet) {
        for index in offsets {
            let alarm = alarms[index]
            AlarmManager.shared.cancel(alarmID: alarm.id)
        }
        alarms.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save alarms: \(error.localizedDescription)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            alarms = try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            print("Failed to load alarms: \(error.localizedDescription)")
            alarms = []
        }
    }
}
