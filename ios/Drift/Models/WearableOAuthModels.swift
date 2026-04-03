//
//  WearableOAuthModels.swift
//  Drift
//
//  Backend contract for multi-brand wearable OAuth (Fitbit, Garmin) vs HealthKit (no OAuth).
//

import Foundation

/// Identifiers aligned with GET /api/v1/wearables/providers.
enum DriftWearableProvider: String, CaseIterable, Identifiable {
    case appleHealthKit = "apple_healthkit"
    case fitbit
    case garmin
    case googleFit = "google_fit"
    case samsung

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleHealthKit: return "Apple Watch / Health"
        case .fitbit: return "Fitbit"
        case .garmin: return "Garmin"
        case .googleFit: return "Google Fit"
        case .samsung: return "Samsung Health"
        }
    }
}

struct WearableProviderInfo: Codable {
    let id: String
    let displayName: String
    let authType: String
    let configured: Bool
    let notes: String?
}

struct WearableAuthorizeResponse: Codable {
    let url: String
    let state: String
    let redirectUri: String
    let provider: String
}

struct WearableExchangeResponse: Codable {
    let ok: Bool
    let provider: String
    let message: String
}
