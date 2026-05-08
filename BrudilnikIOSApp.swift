import SwiftUI

@main
struct BrudilnikIOSApp: App {
    @StateObject private var viewModel = AlarmListViewModel()

    init() {
        AlarmManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
