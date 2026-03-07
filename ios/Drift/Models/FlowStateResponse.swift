//
//  FlowStateResponse.swift
//  Drift
//
//  Response from backend POST /api/v1/hrv_stream.
//

import Foundation

struct FlowStateResponse: Codable, Sendable {
    /// True if HRV is steady/high; false if erratic or below baseline
    var isInFlow: Bool
    /// Current baseline HRV (ms) for debugging
    var baseline: Double?
    /// Short reason for debugging
    var reason: String?

    enum CodingKeys: String, CodingKey {
        case isInFlow = "is_in_flow"
        case baseline
        case reason
    }
}
