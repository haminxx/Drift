//
//  HRVPayload.swift
//  Drift
//
//  Payload sent from Watch to iPhone via WatchConnectivity and from iPhone to backend.
//  Codable for JSON over WatchConnectivity and HTTP.
//

import Foundation

struct HRVPayload: Codable, Sendable {
    /// ISO8601 or Unix timestamp string
    var timestamp: String
    /// HRV SDNN in milliseconds
    var hrvSDNN: Double
    /// Heart rate in bpm (optional)
    var heartRate: Double?
    /// Optional device/session identifiers for backend
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
