import SwiftUI
import UniformTypeIdentifiers

// MARK: - Тема

private enum AlarmTheme {
    static let accent = Color(red: 1, green: 0.58, blue: 0.2)
    static let accentSoft = Color(red: 1, green: 0.72, blue: 0.45)

    static let bgTop = Color(red: 0.07, green: 0.06, blue: 0.14)
    static let bgBottom = Color(red: 0.04, green: 0.08, blue: 0.18)

    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.12)
}

// MARK: - Главный экран

struct ContentView: View {
    @EnvironmentObject private var viewModel: AlarmListViewModel
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                List {
                    if viewModel.alarms.isEmpty {
                        emptyState
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    ForEach(viewModel.alarms) { alarm in
                        AlarmRowCard(
                            alarm: alarm,
                            isOn: Binding(
                                get: { alarm.isEnabled },
                                set: { viewModel.setEnabled($0, for: alarm.id) }
                            )
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: viewModel.deleteAlarm)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Будильник")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarItems(trailing:
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(AlarmTheme.accent, Color.white.opacity(0.9))
                }
                .accessibilityLabel("Добавить будильник")
            )
            .tint(AlarmTheme.accent)
            .sheet(isPresented: $showingAddSheet) {
                AddAlarmView { hour, minute, title, repeatsDaily, soundFileName in
                    viewModel.addAlarm(
                        hour: hour,
                        minute: minute,
                        title: title,
                        repeatsDaily: repeatsDaily,
                        soundFileName: soundFileName
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [AlarmTheme.bgTop, AlarmTheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AlarmTheme.accent.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 120, y: -220)
                .blur(radius: 40)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -140, y: 280)
                .blur(radius: 50)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(AlarmTheme.cardFill)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(AlarmTheme.cardStroke, lineWidth: 1)
                    )

                Image(systemName: "alarm.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AlarmTheme.accentSoft, AlarmTheme.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Пока тихо")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Нажми + и задай время —\nразбудим аккуратно.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Карточка будильника

private struct AlarmRowCard: View {
    let alarm: Alarm
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(alarm.timeLabel)
                    .font(.system(size: 34, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isOn ? .white : .white.opacity(0.45))

                Text(alarm.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                if alarm.repeatsDaily {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption2.weight(.bold))
                        Text("каждый день")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(AlarmTheme.accentSoft.opacity(0.95))
                }

                if let sound = alarm.soundFileName, AlarmSoundStore.fileExists(sound) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.caption2.weight(.bold))
                        Text("своя мелодия")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(AlarmTheme.accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AlarmTheme.cardFill)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AlarmTheme.cardStroke,
                                    AlarmTheme.accent.opacity(isOn ? 0.25 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }
}

// MARK: - Добавление

private struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var title = "Будильник"
    @State private var repeatsDaily = true
    @State private var selectedSoundFileName: String?
    @State private var importedSounds: [(filename: String, label: String)] = []
    @State private var showSoundImporter = false
    @State private var importErrorMessage: String?

    let onSave: (Int, Int, String, Bool, String?) -> Void

    private static var audioImportTypes: [UTType] {
        var types: [UTType] = [.mp3, .mpeg4Audio, .wav, .aiff, .audio]
        if let caf = UTType(filenameExtension: "caf") {
            types.append(caf)
        }
        return types
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AlarmTheme.bgTop, AlarmTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("Отмена", role: .cancel) {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    Text("Новый будильник")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 72, height: 44)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial.opacity(0.45))

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Время")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))

                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                        }
                        .padding(20)
                        .background(cardBackground)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Название")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))

                            TextField("", text: $title, prompt: Text("Например: Подъём").foregroundColor(Color.white.opacity(0.35)))
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AlarmTheme.cardStroke, lineWidth: 1)
                                }
                                .foregroundStyle(.white)
                        }
                        .padding(20)
                        .background(cardBackground)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Звук")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))

                            soundChoiceRow(
                                label: "Системный звук",
                                isSelected: selectedSoundFileName == nil
                            ) {
                                selectedSoundFileName = nil
                            }

                            ForEach(importedSounds, id: \.filename) { item in
                                soundChoiceRow(
                                    label: item.label,
                                    isSelected: selectedSoundFileName == item.filename
                                ) {
                                    selectedSoundFileName = item.filename
                                }
                            }

                            Button {
                                showSoundImporter = true
                            } label: {
                                Label("Загрузить файл (MP3, M4A, WAV…)", systemImage: "square.and.arrow.down")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(AlarmTheme.cardStroke, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(AlarmTheme.accentSoft)

                            Text("Для уведомлений iOS берёт до ~30 секунд; длиннее — обрежется. MP3 конвертируется автоматически.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(cardBackground)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Повтор каждый день")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Один и тот же будильник на все дни")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                            Toggle("", isOn: $repeatsDaily)
                                .labelsHidden()
                                .tint(AlarmTheme.accent)
                        }
                        .padding(20)
                        .background(cardBackground)

                        Button {
                            let components = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
                            let hour = components.hour ?? 7
                            let minute = components.minute ?? 0
                            let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            let sound = selectedSoundFileName.flatMap { AlarmSoundStore.fileExists($0) ? $0 : nil }
                            onSave(hour, minute, finalTitle.isEmpty ? "Будильник" : finalTitle, repeatsDaily, sound)
                            dismiss()
                        } label: {
                            Text("Сохранить")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [AlarmTheme.accentSoft, AlarmTheme.accent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                .foregroundStyle(.black.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .tint(AlarmTheme.accent)
        .preferredColorScheme(.dark)
        .onAppear {
            importedSounds = AlarmSoundStore.listImportedSounds()
        }
        .fileImporter(
            isPresented: $showSoundImporter,
            allowedContentTypes: Self.audioImportTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let name = try AlarmSoundStore.importAudioFile(from: url)
                    importedSounds = AlarmSoundStore.listImportedSounds()
                    selectedSoundFileName = name
                } catch {
                    importErrorMessage = error.localizedDescription
                }
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
        .alert("Не удалось загрузить звук", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("ОК", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    private func soundChoiceRow(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AlarmTheme.accent : .white.opacity(0.35))
                    .imageScale(.large)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AlarmTheme.accent.opacity(0.45) : AlarmTheme.cardStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(AlarmTheme.cardFill)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AlarmTheme.cardStroke, lineWidth: 1)
            }
    }
}
