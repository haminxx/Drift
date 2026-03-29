//
//  WellnessHistoryStore.swift
//  Drift
//
//  Persists recent HRV / flow / stress samples for dashboard charts (local only).
//

import Foundation

@MainActor
final class WellnessHistoryStore: ObservableObject {
    static let shared = WellnessHistoryStore()

    @Published private(set) var samples: [WellnessSample] = []

    private let maxSamples = 500
    private let fileName = "wellness_history.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Drift", isDirectory: true)
    }

    private init() {
        loadFromDisk()
    }

    func append(
        hrvSDNN: Double,
        serverInFlow: Bool?,
        localStressScore: Double,
        source: String,
        date: Date = Date()
    ) {
        let s = WellnessSample(
            date: date,
            hrvSDNN: hrvSDNN,
            serverInFlow: serverInFlow,
            localStressScore: localStressScore,
            source: source
        )
        samples.append(s)
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
        save()
    }

    /// HRV samples in the last `hours` for charting.
    func samples(inLastHours hours: Double) -> [WellnessSample] {
        let cutoff = Date().addingTimeInterval(-hours * 3600)
        return samples.filter { $0.date >= cutoff }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(samples)
            try data.write(to: fileURL.appendingPathComponent(fileName))
        } catch {}
    }

    private func loadFromDisk() {
        let url = fileURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            samples = try JSONDecoder().decode([WellnessSample].self, from: data)
        } catch {}
    }
}
