import SwiftUI

@main
struct BrudilnikIOSApp: App {
    @StateObject private var viewModel = AlarmListViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
