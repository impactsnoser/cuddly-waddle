import AVFoundation
import Foundation

/// Звуки для локальных уведомлений: файл в `Library/Sounds`, формат PCM WAV ≤ ~30 с.
enum AlarmSoundStore {
    private static let maxDurationSeconds: Double = 29.0

    static var soundsDirectoryURL: URL {
        let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let sounds = lib.appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
        return sounds
    }

    /// Список импортированных файлов (только имя) с подписью для UI.
    static func listImportedSounds() -> [(filename: String, label: String)] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: soundsDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let allowed = Set(["wav", "caf"])
        return urls
            .filter { allowed.contains($0.pathExtension.lowercased()) }
            .sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return da > db
            }
            .map { url in
                let name = url.lastPathComponent
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .now
                let fmt = DateFormatter()
                fmt.locale = Locale(identifier: "ru_RU")
                fmt.dateStyle = .short
                fmt.timeStyle = .short
                return (name, "Мелодия · \(fmt.string(from: date))")
            }
    }

    static func fileExists(_ filename: String?) -> Bool {
        guard let filename, !filename.isEmpty else { return false }
        let url = soundsDirectoryURL.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Импорт из пикера (MP3, M4A, WAV, CAF и др.). Возвращает имя файла в `Library/Sounds`.
    static func importAudioFile(from sourceURL: URL) throws -> String {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let ext = sourceURL.pathExtension.lowercased()
        let duration = try audioDuration(at: sourceURL)
        guard duration > 0 else {
            throw NSError(domain: "AlarmSoundStore", code: 10, userInfo: [NSLocalizedDescriptionKey: "Не удалось прочитать длительность"])
        }

        if ext == "caf", duration <= maxDurationSeconds {
            let name = UUID().uuidString + ".caf"
            let destURL = soundsDirectoryURL.appendingPathComponent(name)
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return name
        }

        if ext == "wav", duration <= maxDurationSeconds {
            let name = UUID().uuidString + ".wav"
            let destURL = soundsDirectoryURL.appendingPathComponent(name)
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return name
        }

        // MP3, M4A, AAC, длинные WAV/CAF — в PCM WAV ≤ 30 с (требование iOS для кастомного звука уведомления).
        let name = UUID().uuidString + ".wav"
        let destURL = soundsDirectoryURL.appendingPathComponent(name)
        try convertToNotificationWAV(sourceURL: sourceURL, destURL: destURL)
        return name
    }

    static func deleteSound(filename: String) throws {
        let url = soundsDirectoryURL.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Audio helpers

    private static func audioDuration(at url: URL) throws -> TimeInterval {
        let file = try AVAudioFile(forReading: url)
        let rate = file.fileFormat.sampleRate
        guard rate > 0 else { return 0 }
        return Double(file.length) / rate
    }

    private static func convertToNotificationWAV(sourceURL: URL, destURL: URL) throws {
        let inputFile = try AVAudioFile(forReading: sourceURL)
        let inFormat = inputFile.processingFormat

        let sampleRate: Double = 44100
        guard let outFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: true
        ) else {
            throw NSError(domain: "AlarmSoundStore", code: 30, userInfo: [NSLocalizedDescriptionKey: "Формат выхода"])
        }

        guard let converter = AVAudioConverter(from: inFormat, to: outFormat) else {
            throw NSError(domain: "AlarmSoundStore", code: 31, userInfo: [NSLocalizedDescriptionKey: "Конвертация недоступна для этого файла"])
        }

        let outputFile = try AVAudioFile(forWriting: destURL, settings: outFormat.settings)

        let inCapacity: AVAudioFrameCount = 8192
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: inCapacity) else {
            throw NSError(domain: "AlarmSoundStore", code: 32, userInfo: [NSLocalizedDescriptionKey: "Входной буфер"])
        }

        let maxOutFrames = AVAudioFrameCount(sampleRate * maxDurationSeconds)
        var totalWritten: AVAudioFrameCount = 0

        while totalWritten < maxOutFrames {
            inputBuffer.frameLength = 0
            try inputFile.read(into: inputBuffer)
            if inputBuffer.frameLength == 0 { break }

            let estimatedOut = AVAudioFrameCount(Double(inputBuffer.frameLength) * (sampleRate / inFormat.sampleRate) + 32)
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: max(estimatedOut, 1024)) else {
                break
            }

            try converter.convert(to: outputBuffer, from: inputBuffer)

            var toWrite = outputBuffer.frameLength
            let capLeft = maxOutFrames - totalWritten
            if toWrite > capLeft {
                toWrite = capLeft
                outputBuffer.frameLength = toWrite
            }
            if toWrite == 0 { break }
            try outputFile.write(from: outputBuffer)
            totalWritten += toWrite
        }

        guard totalWritten > 0 else {
            try? FileManager.default.removeItem(at: destURL)
            throw NSError(
                domain: "AlarmSoundStore",
                code: 33,
                userInfo: [NSLocalizedDescriptionKey: "Не получилось сделать звук для уведомления. Попробуй другой файл."]
            )
        }
    }
}
