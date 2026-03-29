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

        let flow = FlowStateManager.shared
        flow.connectHealthKit(health)

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
            if !FlowStateManager.shared.isInEnforcedBreak {
                shield.removeShields()
            }
        }
        timer.onTimerExpired = {
            shield.applyShields()
        }
        wc.activate()
        health.requestAuthorizationIfNeeded { granted in
            if granted {
                health.refreshBaseline()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
