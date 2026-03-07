//
//  WatchConnectivityManager.swift
//  Drift
//
//  Receives HRV payloads from the Watch via WatchConnectivity and forwards to APIClient.
//  No special entitlement beyond WatchConnectivity.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    /// Called when a new HRV payload is received from the Watch; wire this to APIClient.
    var onHRVPayloadReceived: ((HRVPayload) -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Optional: surface activation state for UI
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let payload = decodeHRVPayload(from: message) {
            DispatchQueue.main.async { [weak self] in
                self?.onHRVPayloadReceived?(payload)
            }
        }
        replyHandler(["ack": true])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let payload = decodeHRVPayload(from: userInfo) {
            DispatchQueue.main.async { [weak self] in
                self?.onHRVPayloadReceived?(payload)
            }
        }
    }

    private func decodeHRVPayload(from dict: [String: Any]) -> HRVPayload? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(HRVPayload.self, from: data)
    }
}
