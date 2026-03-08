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
        FirebaseManager.configure()
        let wc = WatchConnectivityManager.shared
        let api = APIClient.shared
        let timer = ShieldTimerManager.shared
        let shield = ShieldManager.shared
        let health = HealthKitManager.shared

        api.authTokenProvider = { await FirebaseManager.shared.getIdToken() }
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
            ContentView()
        }
    }
}
