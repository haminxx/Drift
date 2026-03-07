//
//  DriftApp.swift
//  Drift
//
//  Wire WatchConnectivity and HealthKit (Garmin/Health pipeline) → APIClient → ShieldTimerManager / ShieldManager.
//

import SwiftUI

@main
struct DriftApp: App {
    init() {
        let wc = WatchConnectivityManager.shared
        let api = APIClient.shared
        let timer = ShieldTimerManager.shared
        let shield = ShieldManager.shared
        let health = HealthKitManager.shared

        wc.onHRVPayloadReceived = { payload in
            api.postHRVStream(payload)
        }
        health.onHRVSample = { payload in
            api.postHRVStream(payload)
        }
        api.onFlowStateLost = {
            timer.startWarning()
        }
        api.onFlowStateRestored = {
            timer.cancelWarning()
            shield.removeShield()
        }
        timer.onTimerExpired = {
            shield.applyShield()
        }
        wc.activate()
        health.requestAuthorizationIfNeeded { _ in }
    }

    var body: some Scene {
        WindowGroup {
            // Your UI: connect to ShieldTimerManager.shared.remainingSeconds, etc.
            Text("Drift")
        }
    }
}
