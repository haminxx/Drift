//
//  DriftWatchApp.swift
//  Drift Watch App
//
//  Activates WatchConnectivity and HealthKit; forwards each HRV sample to the iPhone.
//

import SwiftUI

@main
struct DriftWatchApp: App {
    init() {
        let wc = WatchConnectivityManager.shared
        let health = HealthKitManager.shared
        wc.activate()
        health.onHRVSample = { payload in
            wc.send(payload: payload)
        }
        health.requestAuthorization { _ in }
    }

    var body: some Scene {
        WindowGroup {
            Text("Drift")
        }
    }
}
