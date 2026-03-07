//
//  HRVPayload.swift (shared)
//  Use this in a shared framework target if you prefer a single definition.
//  Otherwise the same struct is duplicated in Drift and Drift Watch App.
//

import Foundation

struct HRVPayloadShared: Codable, Sendable {
    var timestamp: String
    var hrvSDNN: Double
    var heartRate: Double?
    var deviceId: String?
    var sessionId: String?
}
