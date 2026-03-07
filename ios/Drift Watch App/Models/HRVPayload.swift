//
//  HRVPayload.swift
//  Drift Watch App
//
//  Same shape as iOS; sent to iPhone via WatchConnectivity.
//

import Foundation

struct HRVPayload: Codable, Sendable {
    var timestamp: String
    var hrvSDNN: Double
    var heartRate: Double?
    var deviceId: String?
    var sessionId: String?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case hrvSDNN = "hrv_sdnn"
        case heartRate = "heart_rate"
        case deviceId = "device_id"
        case sessionId = "session_id"
    }
}
