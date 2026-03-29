//
//  WellnessSample.swift
//  Drift
//
//  One point in time for HRV, server flow verdict, and local stress score for charts.
//

import Foundation

struct WellnessSample: Codable, Identifiable, Sendable {
    var id: UUID
    var date: Date
    /// HRV SDNN in milliseconds
    var hrvSDNN: Double
    /// From backend is_in_flow when available
    var serverInFlow: Bool?
    /// 0 = calm / in flow locally, 1 = stressed vs baseline
    var localStressScore: Double
    /// "health", "watch", etc.
    var source: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        hrvSDNN: Double,
        serverInFlow: Bool?,
        localStressScore: Double,
        source: String
    ) {
        self.id = id
        self.date = date
        self.hrvSDNN = hrvSDNN
        self.serverInFlow = serverInFlow
        self.localStressScore = localStressScore
        self.source = source
    }
}
