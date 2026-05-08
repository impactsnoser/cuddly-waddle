import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AlarmListViewModel
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.alarms.isEmpty {
                    Text("No alarms yet")
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.alarms) { alarm in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alarm.timeLabel)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(alarm.title)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { alarm.isEnabled },
                            set: { viewModel.setEnabled($0, for: alarm.id) }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: viewModel.deleteAlarm)
            }
            .navigationTitle("Brudilnik")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAlarmView { hour, minute, title, repeatsDaily in
                    viewModel.addAlarm(hour: hour, minute: minute, title: title, repeatsDaily: repeatsDaily)
                }
            }
        }
    }
}

private struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var title = "Brudilnik"
    @State private var repeatsDaily = true

    let onSave: (Int, Int, String, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Time", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                TextField("Title", text: $title)
                Toggle("Repeat daily", isOn: $repeatsDaily)
            }
            .navigationTitle("New alarm")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
                        let hour = components.hour ?? 7
                        let minute = components.minute ?? 0
                        onSave(hour, minute, title.isEmpty ? "Brudilnik" : title, repeatsDaily)
                        dismiss()
                    }
                }
            }
        }
    }
}

