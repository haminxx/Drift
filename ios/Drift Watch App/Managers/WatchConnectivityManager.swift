//
//  WatchConnectivityManager.swift
//  Drift Watch App
//
//  Sends HRV payloads to the iPhone via sendMessage or transferUserInfo.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(payload: HRVPayload) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let dict = payloadToDict(payload)
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil, errorHandler: { _ in
                session.transferUserInfo(dict)
            })
        } else {
            session.transferUserInfo(dict)
        }
    }

    private func payloadToDict(_ payload: HRVPayload) -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": payload.timestamp,
            "hrv_sdnn": payload.hrvSDNN,
        ]
        if let hr = payload.heartRate { dict["heart_rate"] = hr }
        if let did = payload.deviceId { dict["device_id"] = did }
        if let sid = payload.sessionId { dict["session_id"] = sid }
        return dict
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
